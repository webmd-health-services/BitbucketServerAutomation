# Overview

Bitbucket Server Automation is a PowerShell module for automating [Bitbucket Server](https://www.atlassian.com/software/bitbucket). Bitbucket Server is Git repository management software that you host on your own server.

With this module, you can:

 * Create and get projects
 * Create, get, and remove repositories
 * Set build status
 
# Installation
 
To download, go to this project's [Github source code repository](https://github.com/pshdo/BitbucketServerAutomation), click the green "Clone or Download" button, and choose "Download ZIP." Once the ZIP file is downloaded, right-click it and choose "Properties". On the Properties dialog box, click the "Unblock" button.
 
To install, open the downloaded ZIP file. The module is in the BitbucketServerAutomation directory. Put that directory anywhere you want. 
 
# Getting Started

First, import the Bitbucket Server Automation module:

    Import-Module 'Path\To\BitbucketServerAutomation
    
If you put it in one of your `PSModulePath` directories, you can omit the path:

    Import-Module 'BitbucketServerAutomation'
 
Next, create a connection object to the instance of Bitbucket Server you want to use along with the credentials to authenticate with.
 
***NOTE: Authentication to Bitbucket Server is done using the HTTP Authorization HTTP header, which is sent in cleartext. Make sure your instance of Bitbucket Server is protected with SSL, otherwise malicous users will be able to see these credentials.***

    $conn = New-BBServerConnection -Uri 'https://bitbucket.example.com' -Credential $credential
    
(The `Credential` parameter is optional and if ommitted, you'll be prompted for the credential to use.)
 
Now, you can create projects:

    New-BBServerProject -Connection $conn -Key 'PSHDO' -Name 'pshdo repositories'
    
You can create repositories:

    New-BBServerRepository -Connection $conn -ProjectKey 'PSHDO' -Name 'BitbucketServerAutomation'
    
To see a full list of available commands:

    Get-Command -Module 'BitbucketServerAutomation'
    
# Contributing

Contributions are welcome and encouraged! First, [create your own copy of this repository by "forking" it](https://help.github.com/articles/fork-a-repo/). 

Next, [clone the repository to your local computer](https://help.github.com/articles/cloning-a-repository/).

Finally, before you can write tests and code, you'll need to install the module's pre-requisites. Run:

    > .\init.ps1
    
This script will install modules needed to develop and run tests. It will also download and install a copy of Bitbucket Server for tests to use. In order to install Bibucket Server, you'll need a trial license from Atlassian. 

We use [Pester](https://github.com/pester/Pester) as our testing framework. A copy of Pester is saved to the repository root directory by `init.ps1`. To run tests, import Pester, and use `Invoke-Pester`:

    > Import-Module '.\Pester'
    > Invoke-Pester '.\Tests'
    
Test scripts go in the `Tests` directory. New functions go in the `BitbucketServerAutomation\Functions` directory. 

# Thanks

We're very grateful to [Atlassian](https://www.atlassian.com/) for supporting our project. They graciously donated a Bitbucket Server license to the project that we use in our automated tests.

