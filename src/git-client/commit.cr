require "json"

struct GitClient::Commit
  include JSON::Serializable

  getter commit : String
  getter subject : String
  getter author : String?
  getter date : String?

  def initialize(
    @commit : String,
    @subject : String,
    @author : String? = nil,
    @date : String? = nil
  )
  end
end
