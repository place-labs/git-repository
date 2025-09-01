require "./spec_helper"

module GitRepository
  describe GitRepository::Generic do
    client = Generic.new("https://github.com/PlaceOS/drivers")

    it "should fetch a specific folder at a ref" do
      Generic.create_temp_folder do |tmp|
        # Fetch the "drivers/ubipark" folder from main branch
        commit = client.fetch_folder("HEAD", "drivers/ubipark", tmp)

        # The return value should be a Commit object
        commit.should be_a(Commit)

        # Files in the target folder should exist
        File.exists?(File.join(tmp, "drivers/ubipark/api.cr")).should be_true

        drivers_path = File.join(tmp, "drivers")
        subfolders = Dir.children(drivers_path).select do |entry|
          File.directory?(File.join(drivers_path, entry))
        end

        # should only have one folder inside drivers/
        subfolders.size.should eq(1)
        subfolders.should eq(["ubipark"])
      end
    end
  end
end
