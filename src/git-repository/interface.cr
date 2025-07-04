require "file_utils"
require "./releases"
require "./commit"
require "./errors"

abstract class GitRepository::Interface
  getter repository : String
  getter username : String?
  getter password : String?
  getter! cached_branch : String
  getter? use_cache : Bool
  getter cache_path : String { create_temp_folder }

  def initialize(@repository : String, @username : String? = nil, @password : String? = nil, branch : String? = nil, @cache_path : String? = nil)
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
  abstract def commits(branch : String, file : String | Enumerable(String), depth : Int? = 50) : Array(Commit)
  abstract def fetch_commit(ref : String, download_to_path : String | Path) : Commit
  abstract def file_list(ref : String? = nil, path : String? = nil) : Array(String)

  module TempFolders
    def create_temp_folder
      temp_folder = File.join(Dir.tempdir, "#{Time.utc.to_unix_ms}_#{rand(9999)}").to_s
      Dir.mkdir temp_folder
      temp_folder
    end

    def create_temp_folder(&)
      temp_folder = create_temp_folder
      begin
        yield temp_folder
      ensure
        # delete the temp folder
        spawn { cleanup(temp_folder) }
      end
    end

    def cleanup(temp_folder : String, tries = 0)
      FileUtils.rm_rf(temp_folder)
    rescue error
      Log.warn(exception: error) { "failed to cleanup folder: #{temp_folder}" }
      if tries < 2
        sleep 1.second
        cleanup(temp_folder, tries + 1)
      end
    end
  end

  extend TempFolders
  include TempFolders
end
