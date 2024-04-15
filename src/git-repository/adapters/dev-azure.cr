require "connect-proxy"
require "../generic"

# API Docs: https://docs.microsoft.com/en-us/rest/api/azure/devops/git/commits/get-commits?view=azure-devops-rest-5.0#on-a-branch
class GitRepository::Adapters::DevAzure < GitRepository::Generic
  getter organization : String
  getter project : String
  getter repo_id : String

  def initialize(@repository : String, @username : String? = nil, @password : String? = nil, branch : String? = nil, @cache_path : String? = nil)
    super

    # https://dev.azure.com/{organization}/{project}/_git/{repositoryId}
    uri = URI.parse(@repository)
    path_components = uri.path.split('/')
    @organization = path_components[1]
    @project = path_components[2]
    @repo_id = path_components[4]
  end

  # no need to cache as we're using an API
  protected def build_cache
    @use_cache = false
  end

  protected def get_commits(branch : String, file : String | Enumerable(String) | Nil = nil, depth : Int? = 50) : Array(Commit)
    uri = URI.parse("https://dev.azure.com/#{organization}/#{project}/_apis/git/repositories/#{repo_id}/commits?searchCriteria.itemVersion.version=#{branch}&api-version=5.0")
    client = ConnectProxy::HTTPClient.new(uri)

    if username && password
      client.basic_auth(username, password)
    end

    params = uri.query_params
    params["searchCriteria.$top"] = depth.to_s if depth

    case file
    in Enumerable(String)
      commits = [] of Commit
      file.each do |path|
        params["searchCriteria.itemPath"] = "/#{path}"
        uri.query_params = params
        response = client.get(uri.request_target)
        raise GitCommandError.new("dev.azure.com commits API request failed with #{response.status_code}\n#{response.body}") unless response.success?

        commits.concat Commits.from_json(response.body).to_commits
        commits.uniq!(&.hash)
      end
      commits.sort { |ref_a, ref_b| ref_b.time <=> ref_a.time }
    in String, Nil
      params["searchCriteria.itemPath"] = "/#{file}" if file
      uri.query_params = params
      response = client.get(uri.request_target)
      raise GitCommandError.new("dev.azure.com commits API request failed with #{response.status_code}\n#{response.body}") unless response.success?
      Commits.from_json(response.body).to_commits
    end
  end

  struct Committer
    include JSON::Serializable

    getter name : String
    getter email : String?
    getter date : String
  end

  struct AzureCommit
    include JSON::Serializable

    getter author : Committer
    getter committer : Committer

    @[JSON::Field(key: "commitId")]
    getter hash : String
    getter comment : String

    def to_commit
      Commit.new(hash, comment, author.name, author.date)
    end
  end

  struct Commits
    include JSON::Serializable

    getter count : Int32
    getter value : Array(AzureCommit)

    def to_commits
      value.map &.to_commit
    end
  end
end
