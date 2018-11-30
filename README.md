[![Build status](https://ci.appveyor.com/api/projects/status/aub8slbmc95s4ikv?svg=true)](https://ci.appveyor.com/project/splatteredbits/bitbucketserverautomation)

# Overview

Bitbucket Server Automation is a PowerShell module for automating [Bitbucket Server](https://www.atlassian.com/software/bitbucket). Bitbucket Server is Git repository management software that you host on your own server.

With this module, you can:

 * Create and get projects
 * Create, get, and remove repositories
 * Set build status

# Installation

## Method 1: Install from PowerShell Gallery

 Ensure you have [PowerShellGet](https://docs.microsoft.com/en-us/powershell/gallery/installing-psget) installed and make [PowerShell Gallery](https://www.powershellgallery.com/) a trusted source:

    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

 Then to install the module run:

    Install-Module -Name BitbucketServerAutomation

## Method 2: Install manually from GitHub

 Download an archive of your desired version from the [Releases](https://github.com/webmd-health-services/BitbucketServerAutomation/releases) section of the repository.

 Extract the downloaded module archive to one of the paths listed in your `$Env:PSModulePath` variable.

    PS C:\> $Env:PSModulePath.Split(';')
    C:\Users\USERNAME\Documents\WindowsPowerShell\Modules
    C:\Program Files\WindowsPowerShell\Modules
    C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules

 For example, to extract the module archive to `C:\Program Files\WindowsPowerShell\Modules` using PowerShell (*requires PowerShell 5+*):

    Expand-Archive -Path 'BitbucketServerAutomation.zip' -DestinationPath 'C:\Program Files\WindowsPowerShell\Modules'

# Getting Started

First, import the Bitbucket Server Automation module:

    Import-Module 'Path\To\BitbucketServerAutomation'

If you put it in one of your `PSModulePath` directories, you can omit the path:

    Import-Module 'BitbucketServerAutomation'

Next, create a connection object to the instance of Bitbucket Server you want to use along with the credentials to authenticate with.

***NOTE: Authentication to Bitbucket Server is done using the [HTTP Authorization](https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication) header, which is sent in cleartext. Make sure your instance of Bitbucket Server is protected with SSL, otherwise malicous users will be able to see these credentials.***

    $conn = New-BBServerConnection -Uri 'https://bitbucket.example.com' -Credential $credential

(The `Credential` parameter is optional and if ommitted, you'll be prompted for the credential to use.)

Now, you can create projects:

    New-BBServerProject -Connection $conn -Key 'PSMODULE' -Name 'PowerShell Modules'

You can create repositories:

    New-BBServerRepository -Connection $conn -ProjectKey 'PSMODULE' -Name 'BitbucketServerAutomation'

To see a full list of available commands:

    Get-Command -Module 'BitbucketServerAutomation'

# Contributing

## Setting Up

Contributions are welcome and encouraged! First, [create your own copy of this repository by "forking" it](https://help.github.com/articles/fork-a-repo/).

Next, [clone the repository to your local computer](https://help.github.com/articles/cloning-a-repository/).

Finally, before you can write tests and code, you'll need to first install the module's pre-requisites with:

    .\init.ps1

This script will download and install Bitbucket Server on the local computer for tests to use. In order to install Bitbucket Server, you'll need to obtain a trial license from Atlassian and place that license in a `.bbserverlicense` file in the root of the repository.

## Building and Testing

We use [Whiskey](https://github.com/webmd-health-services/Whiskey) to build, test, and publish the module. [Pester](https://github.com/pester/Pester) is the testing framework used for our tests. To build and run all tests, use the `build.ps1` script:

    .\build.ps1

If you want to run only specific tests, first import `Pester`:

    Import-Module -Name '.\PSModules\Pester'

Then invoke a single test script:

    Invoke-Pester -Path .\Tests\New-BBServerRepository.Tests.ps1

Test scripts go in the `Tests` directory. New module functions go in the `BitbucketServerAutomation\Functions` directory.

# Thanks

We're very grateful to [Atlassian](https://www.atlassian.com/) for supporting our project. They graciously donated a Bitbucket Server license to the project that we use in our automated tests.

