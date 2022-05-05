require "./commit"

module GitRepository
  class Error < Exception
  end

  class GitCommandError < Error
  end

  class APIError < Error
  end
end
