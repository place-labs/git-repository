require "./spec_helper"

module GitClient
  describe GitClient::Generic do
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

      (branch_commits.map(&.commit) != file_commits.map(&.commit)).should be_true
    end
  end
end
