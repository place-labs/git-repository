require "./interface"
require "./commands"

class GitRepository::Generic < GitRepository::Interface
  def initialize(@repository : String, @username : String? = nil, @password : String? = nil, branch : String? = nil, @cache_path : String? = nil)
    super

    # Ensure cache folder exists and is ready to list commits
    build_cache if use_cache?
  end

  # This caches the git history and nothing else
  protected def build_cache
    Commands.new(cache_path).commits(@repository, cached_branch, depth: nil)
  end

  def finalize
    FileUtils.rm_rf(cache_path) if use_cache?
  rescue
    # we can ignore failures here
  end

  def default_branch : String
    stdout = Commands.new.run_git("ls-remote", {"--symref", @repository, "HEAD"}).to_s
    begin
      stdout.to_s.split("ref: refs/heads/", 2)[1].split('\t', 2)[0]
    rescue error
      raise GitCommandError.new(
        message: "failed to parse default branch output\n#{stdout}",
        cause: error
      )
    end
  end

  protected def ls_remote(type : String)
    output = Commands.new.run_git("ls-remote", {"--#{type}", @repository}).to_s.split('\n')
    split_string = "#{type}/"
    output.compact_map do |ref|
      next if ref.empty?
      parts = ref.split('\t', limit: 2)
      next unless parts.size == 2
      # ref => commit hash
      {parts[1].split(split_string, 2)[1], parts[0]}
    end.to_h
  end

  def branches : Hash(String, String)
    ls_remote("heads")
  end

  def tags : Hash(String, String)
    ls_remote("tags")
  end

  protected def get_commits(branch : String, file : String | Enumerable(String) | Nil = nil, depth : Int? = 50) : Array(Commit)
    if use_cache? && branch == cached_branch
      commands = Commands.new(cache_path)
      commands.pull_logs
      commands.commits(file, depth)
    else
      create_temp_folder do |temp_folder|
        if file
          # We need to download the full repo history to grab the file history
          commands = Commands.new(temp_folder)
          commands.clone_logs(@repository, branch, depth: nil)
          commands.commits(file, depth)
        else
          Commands.new(temp_folder).commits(@repository, branch, nil, depth)
        end
      end
    end
  end

  def commits(branch : String, depth : Int? = 50) : Array(Commit)
    get_commits(branch, depth: depth)
  end

  def commits(branch : String, file : String | Enumerable(String), depth : Int? = 50) : Array(Commit)
    get_commits(branch, file, depth)
  end

  protected def move_into_place(new_files, target_folder) : Nil
    # move any existing files out of the way
    if Dir.exists?(target_folder)
      # We move the existing files to a temp folder on the same volume
      # same volume for speed, the cleanup might take some time if there are a lot of files
      old_existing_files = "#{target_folder.chomp('/')}_temp_#{rand(9999)}"
      FileUtils.mv(target_folder, old_existing_files)
    end

    # move the new files into place
    # likely to be across the network when on a k8s mounted shared volume
    begin
      FileUtils.mv(new_files, target_folder)
    rescue error
      # attempt to restore state on failure
      if old_existing_files
        FileUtils.rm_rf(target_folder)
        FileUtils.mv(old_existing_files, target_folder)
      end
      raise error
    end

    # cleanup old files without blocking
    if old_existing_files
      spawn { FileUtils.rm_rf(old_existing_files) }
    end
  end

  def fetch_commit(ref : String, download_to_path : String | Path) : Commit
    download_to = download_to_path.to_s

    # download the commit
    create_temp_folder do |temp_folder|
      git = Commands.new(temp_folder)
      git.init
      git.add_origin @repository
      git.fetch ref             # git fetch --depth 1 origin <sha1>
      git.checkout "FETCH_HEAD" # git checkout FETCH_HEAD

      move_into_place(temp_folder, download_to)

      # grab the current commit hash
      git.path = download_to
      git.commits(depth: 1).first
    end
  end

  def fetch_commit(branch : String, commit : String, source_file : String, download_to_path : String | Path) : Commit
    download_to = download_to_path.to_s

    # download the commit
    create_temp_folder do |temp_folder|
      git = Commands.new(temp_folder)
      git.init
      git.add_origin @repository
      git.fetch_all branch             # git fetch origin branch
      git.checkout branch              # git checkout branch or FETCH_HEAD
      git.checkout commit, source_file # git checkout FETCH_HEAD or sha1 -- source_file

      move_into_place(temp_folder, download_to)

      # grab the current commit hash
      git.path = download_to
      git.commits(depth: 1).first
    end
  end
end
