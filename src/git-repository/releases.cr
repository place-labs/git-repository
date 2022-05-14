require "./commit"

module GitRepository::Releases
  abstract def releases(count : Int32 = 50) : Array(String)
  abstract def fetch_release(version : String, download_to_path : String | Path) : Nil
end
