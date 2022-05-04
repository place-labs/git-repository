require "./commit"

module GitClient
  class Error < Exception
  end

  class GitCommandError < Error
  end

  class APIError < Error
  end
end
