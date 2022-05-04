require "./commit"

abstract class GitClient::Interface
  getter repository : String
  getter username : String?
  getter password : String?

  def initialize(@repository : String, @username : String? = nil, @password : String? = nil)
    uri = URI.parse(@repository)
    uri.user = uri.user || username
    uri.password = uri.password || password
    @repository = uri.to_s
  end

  abstract def default_branch : String
  abstract def branches : Hash(String, String)
  abstract def tags : Hash(String, String)
  abstract def releases : Array(String)
  abstract def commits(branch : String, depth : Int? = 50) : Array(Commit)
  abstract def commits(branch : String, file : String, depth : Int? = 50) : Array(Commit)

  abstract def fetch_branch(branch : String, download_to_path : String | Path) : Nil
  abstract def fetch_commit(hash_or_tag : String, download_to_path : String | Path) : Nil
  abstract def fetch_release(version : String, download_to_path : String | Path) : Nil
end
