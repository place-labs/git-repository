require "./spec_helper"

module GitRepository::Adapters
  describe GitRepository::Adapters::DevAzure do
    client = DevAzure.new("https://dev.azure.com/steve0261/devops-api/_git/devops-api")

    it "should return the default branch" do
      client.default_branch.should eq "master"
    end

    it "should return the list of branches" do
      branches = client.branches
      branches.keys.includes?("master").should eq true
      branches.size.should eq 1
    end

    it "should return commits" do
      branch_commits = client.commits("master", 5)
      branch_commits.size.should eq 2
      file_commits = client.commits("master", "testing.txt", 5)
      file_commits.size.should eq 1
      branch_commits = client.commits("master", 1)
      branch_commits.size.should eq 1
    end

    it "should return commits for multiple files" do
      branch_commits = client.commits("master", 5)
      branch_commits.size.should eq 2
      file_commits = client.commits("master", {"testing.txt", "second.txt"}, 5)
      file_commits.size.should eq 2
    end
  end
end
