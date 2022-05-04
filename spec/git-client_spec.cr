require "./spec_helper"

describe GitClient do
  client = GitClient.new("https://github.com/PlaceOS/backoffice")

  it "should instansiate a client" do
    client.is_a?(GitClient::Generic).should be_true
  end
end
