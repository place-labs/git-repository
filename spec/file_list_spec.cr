require "./spec_helper"

module GitRepository
  describe GitRepository::Generic do
    client = Generic.new("https://github.com/PlaceOS/drivers")

    it "should list files in the repository" do
      # all files
      files = client.file_list
      files.includes?("drivers/ubipark/api.cr").should be_true

      # files from an earlier commit
      files = client.file_list("c0536e9c7b5bfe6e40e850717f377846090f50ea")
      files.includes?("drivers/ubipark/api.cr").should be_false

      # files filtered by folder
      files.includes?("shard.yml").should be_true

      files = client.file_list(path: "drivers/")
      files.includes?("drivers/ubipark/api.cr").should be_true
      files.includes?("shard.yml").should be_false
    end
  end
end
