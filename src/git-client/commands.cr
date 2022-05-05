require "./commit"

struct GitClient::Commands
  def initialize(@path : String)
  end

  # NOTE:: assumes this path exists!
  property path

  def init
    stdout = IO::Memory.new
    success = Process.new("git", {"-C", path, "init"}, output: stdout, error: stdout).wait.success?
    raise GitCommandError.new("failed to init git repository\n#{stdout}") unless success
  end

  def remove_origin
    # This only fails when there is no origin specified
    Process.new("git", {"-C", path, "remote", "remove", "origin"}).wait.success?
  end

  def add_origin(repository_uri : String)
    stdout = IO::Memory.new
    success = Process.new("git", {"-C", path, "remote", "add", "origin", repository_uri}, output: stdout, error: stdout).wait.success?
    raise GitCommandError.new("failed to add git origin #{repository_uri.inspect}\n#{stdout}") unless success
  end

  def fetch(branch : String)
    stdout = IO::Memory.new
    success = Process.new("git", {"-C", path, "fetch", "--depth", "1", "origin", branch}, output: stdout, error: stdout).wait.success?
    raise GitCommandError.new("failed to git fetch #{branch.inspect}\n#{stdout}") unless success
  end

  def checkout(branch : String)
    stdout = IO::Memory.new
    success = Process.new("git", {"-C", path, "checkout", branch}, output: stdout, error: stdout).wait.success?
    raise GitCommandError.new("failed to git checkout #{branch.inspect}\n#{stdout}") unless success
  end

  def reset
    stdout = IO::Memory.new
    success = Process.new("git", {"-C", path, "reset", "--hard"}, output: stdout, error: stdout).wait.success?
    raise GitCommandError.new("failed to git reset\n#{stdout}") unless success

    stdout = IO::Memory.new
    success = Process.new("git", {"-C", path, "clean", "-fd", "-fx"}, output: stdout, error: stdout).wait.success?
    raise GitCommandError.new("failed to git clean\n#{stdout}") unless success
  end

  # clones just the repository history
  def clone_logs(repository_uri : String, branch : String, depth : Int? = 50)
    args = ["-C", path, "clone", repository_uri, "-b", branch]
    args.concat({"--depth", depth.to_s}) if depth
    # bare repo, no file data, quiet clone, . = clone into current directory
    args.concat({"--bare", "--filter=blob:none", "-q", "."})

    stdout = IO::Memory.new
    success = Process.new("git", args, output: stdout, error: stdout).wait.success?
    raise GitCommandError.new("failed to clone git history from remote\n#{stdout}") unless success
  end

  # pull latest logs
  def pull_logs
    stdout = IO::Memory.new
    success = Process.new("git", {"-C", path, "fetch", "origin", "+refs/heads/*:refs/heads/*", "--prune"}, output: stdout, error: stdout).wait.success?
    raise GitCommandError.new("failed to update cache from remote\n#{stdout}") unless success
  end

  # clone and grab commits
  def commits(repository_uri : String, branch : String, file : String? = nil, depth : Int? = 50)
    clone_logs(repository_uri, branch, depth)
    commits(file, depth)
  end

  LOG_FORMAT = "format:%H%n%cI%n%an%n%s%n<--%n%n-->"

  # grab commits from cached repository
  def commits(file : String? = nil, depth : Int? = 50)
    stdout = IO::Memory.new
    args = [
      "--no-pager",
      "-C", path,
      "log",
      "--format=#{LOG_FORMAT}",
      "--no-color",
    ]
    args.concat({"-n", depth.to_s}) if depth
    args.concat({"--", file.to_s}) if file
    success = Process.new("git", args, output: stdout, error: stdout).wait.success?
    raise GitCommandError.new("failed to obtain git history\n#{stdout}") unless success

    stdout.tap(&.rewind)
      .each_line("<--\n\n-->")
      .reject(&.empty?)
      .map { |line|
        commit = line.strip.split("\n").map(&.strip)
        Commit.new(
          hash: commit[0],
          subject: commit[3],
          author: commit[2],
          date: commit[1]
        )
      }.to_a
  end
end
