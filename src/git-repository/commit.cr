require "json"

struct GitRepository::Commit
  include JSON::Serializable

  getter hash : String
  getter subject : String
  getter author : String?
  getter date : String?

  def initialize(
    @hash : String,
    @subject : String,
    @author : String? = nil,
    @date : String? = nil
  )
  end
end