# Git Client for inspecting remote git repositories

[![CI](https://github.com/place-labs/git-repository/actions/workflows/ci.yml/badge.svg)](https://github.com/place-labs/git-repository/actions/workflows/ci.yml)

The aim of this shard is to inspect any remote git repository

* fetch repository details remotely (default branch, branches and tags)
* obtain log history without downloading any files
* fetch any branch, tag or commit without downloading history. Minimal data transfer

## Installation

Add the dependency to your `shard.yml`:

  ```yaml
    dependencies:
      git-repository:
        github: place-labs/git-repository
  ```

## Usage

NOTE:: We shell out to `git` to perform these operations

```crystal

repo = GitRepository.new("https://github.com/your/repo", "optional_user", "optional_pass")

repo.default_branch # => "main"
repo.branches       # => {"feature1" => "<head_hash>", "main" => "<head_hash>"}
repo.tags           # => {"v1.1.0" => "<commit_hash>", "v1.0.0" => "<commit_hash>"}
repo.commits("main", depth: 5) # => [Commit]

# Fetch the head of the selected branch
repo.fetch_branch("main", "./your_repo_folder")

# Fetch the repo at a specific commit or tag
repo.fetch_commit("v1.1.0", "./your_repo_folder")

```
