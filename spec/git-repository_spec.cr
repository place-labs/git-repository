require "./spec_helper"

describe GitRepository do
  client = GitRepository.new("https://github.com/PlaceOS/backoffice")

  it "should instansiate a client" do
    client.is_a?(GitRepository::Generic).should be_true
  end
end
