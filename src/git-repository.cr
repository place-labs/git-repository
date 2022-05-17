require "uri"

module GitRepository
  {% begin %}
    VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify.downcase }}
  {% end %}

  def self.new(repository : String | URI, username : String? = nil, password : String? = nil, branch : String? = nil) : GitRepository::Interface
    uri = repository.is_a?(URI) ? repository : URI.parse(repository)
    downcased_host = uri.host.try &.downcase

    username = uri.user || username
    password = uri.password || password

    case downcased_host
    when "dev.azure.com"
      GitRepository::Adapters::DevAzure.new(uri.to_s, username, password, branch.presence)
    else
      GitRepository::Generic.new(uri.to_s, username, password, branch.presence)
    end
  end
end

require "./git-repository/generic"
require "./git-repository/adapters/dev-azure"
