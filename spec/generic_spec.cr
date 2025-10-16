require "./spec_helper"

module GitRepository
  describe GitRepository::Generic do
    client = Generic.new("https://github.com/PlaceOS/backoffice")

    it "should return the default branch" do
      client.default_branch.should eq "develop"
    end

    it "should return the list of branches" do
      branches = client.branches
      branches.keys.includes?("develop").should eq true
      branches.size.should be >= 2
    end

    it "should return the list of tags" do
      branches = client.tags
      branches.keys.includes?("v1.10.0").should eq true
      branches.size.should be >= 2
    end

    it "should return commits" do
      branch_commits = client.commits("develop", 5)
      branch_commits.size.should eq 5
      file_commits = client.commits("develop", "package.json", 5)
      file_commits.size.should eq 5

      (branch_commits.map(&.hash) != file_commits.map(&.hash)).should be_true
    end

    it "should return commits for multiple files" do
      file_commits = client.commits("develop", {"package.json", ".gitignore"}, 5)
      file_commits.size.should eq 5
    end

    it "should work with a history cache" do
      cached_client = Generic.new("https://github.com/PlaceOS/backoffice", branch: "develop")

      branch_commits = cached_client.commits("develop", 5)
      branch_commits.size.should eq 5
      file_commits = cached_client.commits("develop", "package.json", 5)
      file_commits.size.should eq 5

      (branch_commits.map(&.hash) != file_commits.map(&.hash)).should be_true

      cache_path = cached_client.cache_path
      cached_client = nil

      GC.collect
      sleep 200.milliseconds
      GC.collect

      cached_client.should be_nil
      Dir.exists?(cache_path).should be_false
    end

    it "should download a shallow copy of the specified ref" do
      folder_was = ""
      client.create_temp_folder do |path|
        folder_was = path
        commit = client.fetch_commit("build/dev", path)
        commit.hash.size.should be >= 40
        Dir.entries(path).includes?("index.html").should be_true
      end
      sleep 200.milliseconds

      # check we're checking a path
      folder_was.size.should be >= 1
      Dir.exists?(folder_was).should be_false
    end

    it "should return file contents" do
      # Test getting file contents from default branch
      contents = client.file_contents(path: "package.json", branch: "develop")
      contents.should_not be_empty
      contents.should contain("name")
      contents.should contain("version")

      # Test getting file contents from a specific ref
      commits = client.commits("develop", "package.json", 1)
      ref_contents = client.file_contents(ref: commits.first.hash, path: "package.json", branch: "develop")
      ref_contents.should_not be_empty
      ref_contents.should contain("name")
    end
  end
end
