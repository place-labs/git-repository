require "uri"

module GitClient
  {% begin %}
    VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify.downcase }}
  {% end %}

  def self.new(repository : String, username : String? = nil, password : String? = nil) : GitClient::Interface
    uri = URI.parse(repository)
    downcased_host = uri.host.try &.downcase

    username = uri.user || username
    password = uri.password || password

    case downcased_host
    # case "www.github.com", "github.com"
    # once we add specific providers
    else
      GitClient::Generic.new(repository, username, password)
    end
  end
end

require "./git-client/generic"
