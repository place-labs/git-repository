require "./commit"

struct GitRepository::Commands
  def initialize(@path : String = "")
  end

  # NOTE:: assumes this path exists!
  property path

  def init
    run_git("init", Tuple.new)
  end

  def remove_origin
    # This only fails when there is no origin specified
    run_git("remote", {"remove", "origin"})
  rescue
  end

  def add_origin(repository_uri : String)
    run_git("remote", {"add", "origin", repository_uri})
  end

  def fetch(branch : String)
    run_git("fetch", {"--depth", "1", "origin", branch})
  end

  def checkout(branch : String)
    run_git("checkout", {branch})
  end

  def reset
    run_git("reset", {"--hard"})
    run_git("clean", {"-fd", "-fx"})
  end

  # clones just the repository history
  def clone_logs(repository_uri : String, branch : String, depth : Int? = 50)
    args = [repository_uri, "-b", branch]
    args.concat({"--depth", depth.to_s}) if depth
    # bare repo, no file data, quiet clone, . = clone into current directory
    args.concat({"--bare", "--filter=blob:none", "-q", "."})
    run_git("clone", args)
  end

  # pull latest logs
  def pull_logs
    run_git("fetch", {"origin", "+refs/heads/*:refs/heads/*", "--prune"})
  end

  # clone and grab commits
  def commits(repository_uri : String, branch : String, file : String? = nil, depth : Int? = 50)
    clone_logs(repository_uri, branch, depth)
    commits(file, depth)
  end

  LOG_FORMAT = "format:%H%n%cI%n%an%n%s%n<--%n%n-->"

  # grab commits from cached repository
  def commits(file : String? = nil, depth : Int? = 50)
    args = [
      "--format=#{LOG_FORMAT}",
      "--no-color",
    ]
    args.concat({"-n", depth.to_s}) if depth
    args.concat({"--", file.to_s}) if file
    stdout = run_git("log", args)
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

  def run_git(command : String, args : Enumerable, timeout : Time::Span = 5.minutes)
    stdout = IO::Memory.new
    git_args = [
      "--no-pager",
      "-C", path,
      command,
    ].concat(args)

    result = Channel(Bool).new(1)
    process_launched = Channel(Process?).new(1)
    spawn do
      begin
        Process.run(
          "git", git_args,
          output: stdout,
          error: stdout,
          input: Process::Redirect::Close,
        ) do |process|
          process_launched.send(process)
        end
        status = $?
        result.send(status.success?)
      rescue error
        process_launched.send(nil)
      end
    end

    if process = process_launched.receive
      select
      when success = result.receive
        raise GitCommandError.new("failed to git #{command}\n#{stdout}") unless success
      when timeout(timeout)
        process.terminate
        raise IO::TimeoutError.new("git operation took too long\n#{stdout}")
      end
    else
      raise "failed to launch git process"
    end

    stdout
  end
end
