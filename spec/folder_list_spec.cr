require "./spec_helper"

module GitRepository
  describe GitRepository::Generic do
    client = Generic.new("https://github.com/PlaceOS/drivers")

    it "should list folders in the repository" do
      # all folders
      folders = client.folder_list
      folders.includes?("shard.yml").should be_false
    end
  end
end
