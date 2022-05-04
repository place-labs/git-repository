# Git Client for inspecting remote git repositories

[![CI](https://github.com/place-labs/git-client/actions/workflows/ci.yml/badge.svg)](https://github.com/place-labs/git-client/actions/workflows/ci.yml)

The aim of this client is to inspect any remote git repository

* fetch repository details remotely (default branch, branches and tags)
* obtain log history without downloading any files
* fetch any branch, tag or commit without downloading history. Minimal data transfer

## Installation

Add the dependency to your `shard.yml`:

  ```yaml
    dependencies:
      git-client:
        github: place-labs/git-client
  ```

## Usage

NOTE:: We shell out to `git` to perform these operations

```crystal

client = GitClient.new("https://github.com/your/repo", "optional_user", "optional_pass")

client.default_branch # => "main"
client.branches       # => {"feature1" => "<head_hash>", "main" => "<head_hash>"}
client.tags           # => {"v1.1.0" => "<commit_hash>", "v1.0.0" => "<commit_hash>"}
client.commits("main", depth: 5) # => [Commit]

# Fetch the head of the selected branch
client.fetch_branch("main", "./your_repo_folder")

# Fetch the repo at a specific commit or tag
client.fetch_commit("v1.1.0", "./your_repo_folder")

```
