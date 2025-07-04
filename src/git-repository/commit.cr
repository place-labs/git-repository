require "json"

struct GitRepository::Commit
  include JSON::Serializable

  getter hash : String
  getter subject : String
  getter author : String?
  getter date : String?

  getter commit : String

  @[JSON::Field(ignore: true)]
  getter time : Time { Time.parse_rfc3339(date.not_nil!) }

  def initialize(
    @hash : String,
    @subject : String,
    @author : String? = nil,
    @date : String? = nil,
  )
    @commit = @hash
  end
end
