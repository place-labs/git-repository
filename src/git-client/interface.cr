require "./commit"

abstract class GitClient::Interface
  getter repository : String
  getter username : String?
  getter password : String?
  getter! cached_branch : String
  getter? use_cache : Bool

  def initialize(@repository : String, @username : String? = nil, @password : String? = nil, branch : String? = nil)
    uri = URI.parse(@repository)
    uri.user = uri.user || username
    uri.password = uri.password || password
    @repository = uri.to_s
    @cached_branch = branch.presence
    @use_cache = !!@cached_branch
  end

  abstract def default_branch : String
  abstract def branches : Hash(String, String)
  abstract def tags : Hash(String, String)
  abstract def commits(branch : String, depth : Int? = 50) : Array(Commit)
  abstract def commits(branch : String, file : String, depth : Int? = 50) : Array(Commit)
  abstract def fetch_commit(ref : String, download_to_path : String | Path) : Commit

  module TempFolders
    def create_temp_folder
      temp_folder = File.join(Dir.tempdir, "#{Time.utc.to_unix_ms}_#{rand(9999)}").to_s
      Dir.mkdir temp_folder
      temp_folder
    end

    def create_temp_folder
      temp_folder = create_temp_folder
      begin
        yield temp_folder
      ensure
        # delete the temp folder
        spawn { FileUtils.rm_rf(temp_folder) }
      end
    end
  end

  extend TempFolders
  include TempFolders
end
