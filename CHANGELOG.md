<!--markdownlint-disable MD012 no-multiple-blanks-->
<!--markdownlint-disable MD024 no-duplicate-heading-->

# BitbucketServerAutomation Changelog

## 1.1.1

> Released 10 Jan 2024

Complete release notes missing from CHANGELOG.md.


## 1.1.0

> Released 12 Sep 2023

Fixed: the `Get-BBServerFileContent.ps1` function does not return raw content from JSON files.


## 1.0.0

> Released 15 Jan 2021

* Created function `Get-BBServerFileContent` to get the raw content of a file from a repository.
* Imports faster (merged individual function files into module's .psm1 file).


## 0.10.0

> Released 1 Dec 2020

* Created `Get-BBServerUser` function for getting a Bitbucket Server user account.
* Added a `Parameter` parameter to `Invoke-BBServerRestMethod` which takes a hashtable representing the request query
  parameters to include when calling an API resource.
* Created `Get-BBServerDefaultReviewer` function for getting all default reviewer conditions for a project or
  repository.
* Created `New-BBServerDefaultReviewer` function for creating a new default reviewer pull request condition for a
  project or repository.
* Created `Set-BBServerDefaultReviewer` function for updating an existing default reviewer pull request condition for a
  project or repository.


## 0.9.0

> Released 11 Jan 2019

* Created `Get-BBServerUser` function for getting a Bitbucket Server user account.
* Added a `Parameter` parameter to `Invoke-BBServerRestMethod` which takes a hashtable representing the request query
  parameters to include when calling an API resource.
* Created `Get-BBServerDefaultReviewer` function for getting all default reviewer conditions for a project or
  repository.
* Created `New-BBServerDefaultReviewer` function for creating a new default reviewer pull request condition for a
  project or repository.
* Created `Set-BBServerDefaultReviewer` function for updating an existing default reviewer pull request condition for a
  project or repository.


## 0.8.0

> Released 3 Dec 2018

* Created `Get-BBServerHook` function to retrieve hooks from a repository.
* Created `Enable-BBServerHook` function to enable a hook in a repository.
* Created `Disable-BBServerHook` function to disable a hook in a repository.
* Updated `Invoke-BBServerRestMethod` function to handle logic for paged API calls.


## 0.7.0

> Released 23 Aug 2017

* ***BREAKING CHANGE***: Renamed `Get-BBServerChanges` to `Get-BBServerChange`.


## 0.6.0

> Released 17 Aug 2017

* Created `Get-BBServerChanges` function that gets the changes between two commits in a repository.


## 0.5.0

> Released 11 Aug 2017

* Created `Find-BBServerRepository` function for finding a repository without knowing what the project is.


## 0.4.0

> Released 1 Aug 2017

* Created `Get-BBServerPullRequest` function for getting pull requests.
* Created `Merge-BBServerPullRequest` function for merging a pull request.
* Created `New-BBServerPullRequest` function for creating a pull request.
* Renamed `Get-BBServerFile` function's `FilePath` and `FileName` parameters to `Path` and `Filter`, respectively, to
  make it clearer what each parameter does.
* `Get-BBServerFile` now filters on the whole path, not just the file name.


## 0.3.0

> Released 24 Jul 2017

* Added `Get-BBServerPullRequestSetting` function for getting the pull request settings for a repository.
* Added `Set-BBServerPullRequestSetting` function for setting the pull request settings for a repository.
* Added `Move-BBServerRepository` function for moving repositories between projects.
* Added `Rename-BBServerRepository` function for renaming an existing repository.
* Fixed: in some failure scenarios, the web requests error handler fails.


## 0.2.3

> Released 15 Jul 2017

Made examples in help topics more generic.


## 0.2.2

> Released 14 Jul 2017

Fixed: Calling any Bitbucket Server API that has a body in its request fails under PowerShell 5.1.


## 0.2.1

> Released 17 Jun 2017

Fixed: the `Get-BBServerTag` function doesn't return individual tag objects.


## 0.2.0

> Released 13 Jun 2017

### Added

* New `Get-BBServerBranch` function for getting the branches in a repository.
* New `Get-BBServerFile` function for getting a file from a repository.
* New `New-BBServerBranch` function for creating a branch in a repository.
* New `SEt-BBServerDefaultBranch` function for setting a repository's default branch.


## 0.1.0

> Released 5 Jun 2017

### Added

* Added `Get-BBServerCommitBuildStatus` function for getting the build status of a commit.
* Added `Get-BBServerProject` function for getting projects.
* Added `Get-BBServerTag` function for getting tags in a repository.
* Added `New-BBServerProject` function for creating projects.
* Added `New-BBServerTag` function for creating tags in a repository.

### Fixed

* `Set-BBServerCommitBuildStatus` ignores parameter values when they are passed, i.e. it only works when run under
  Jenkins.
