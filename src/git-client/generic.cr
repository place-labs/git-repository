require "./interface"
require "file_utils"
require "dir"

class GitClient::Generic < GitClient::Interface
  def default_branch : String
    stdout = IO::Memory.new
    success = Process.new("git", {"ls-remote", "--symref", @repository, "HEAD"}, output: stdout, error: stdout).wait.success?
    raise GitCommandError.new("failed to obtain default branch\n#{stdout}") unless success
    stdout = stdout.to_s
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
    stdout = IO::Memory.new
    success = Process.new("git", {"ls-remote", "--#{type}", @repository}, output: stdout, error: stdout).wait.success?
    raise GitCommandError.new("failed to obtain remote refs\n#{stdout}") unless success
    output = stdout.to_s.split('\n')

    split_string = "#{type}/"
    output.compact_map do |ref|
      next if ref.empty?
      parts = ref.split('\t', limit: 2)
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

  def releases : Array(String)
    [] of String
  end

  protected def get_commits(branch : String, file : String? = nil, depth : Int? = 50) : Array(Commit)
    temp_folder = Time.utc.to_unix_ms.to_s + rand(9999).to_s
    begin
      Dir.mkdir temp_folder
      Commands.new(temp_folder).commits(@repository, branch, file, depth)
    ensure
      # delete the temp folder
      spawn { FileUtils.rm_rf(temp_folder) }
    end
  end

  def commits(branch : String, depth : Int? = 50) : Array(Commit)
    get_commits(branch, depth: depth)
  end

  def commits(branch : String, file : String, depth : Int? = 50) : Array(Commit)
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

  protected def create_temp_folder
    temp_folder = "#{Time.utc.to_unix_ms}_#{rand(9999)}"
    Dir.mkdir temp_folder
    temp_folder
  end

  def fetch_branch(branch : String, download_to_path : String | Path) : Nil
    download_to = download_to_path.to_s

    # download the commit
    temp_folder = create_temp_folder
    git = GitRepo.new(temp_folder)
    git.init
    git.add_origin @repository
    git.fetch branch    # git fetch --depth 1 origin branch
    git.checkout branch # git checkout branch

    move_into_place(temp_folder, download_to)
  end

  def fetch_commit(hash_or_tag : String, download_to_path : String | Path) : Nil
    download_to = download_to_path.to_s

    # download the commit
    temp_folder = create_temp_folder
    git = GitRepo.new(temp_folder)
    git.init
    git.add_origin @repository
    git.fetch hash_or_tag     # git fetch --depth 1 origin <sha1>
    git.checkout "FETCH_HEAD" # git checkout FETCH_HEAD

    move_into_place(temp_folder, download_to)
  end

  def fetch_release(version : String, download_to_path : String | Path) : Nil
    raise NotImplementedError.new("release downloads are not supported for this repository: #{@repository}")
  end
end
