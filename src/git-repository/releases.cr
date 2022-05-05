require "./commit"

module GitRepository::Releases
  abstract def releases : Array(String)
  abstract def fetch_release(version : String, download_to_path : String | Path) : Nil
end
