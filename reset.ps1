# Copyright 2016 - 2018 WebMD Health Services
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[CmdletBinding(DefaultParameterSetName='All')]
param(
)

Set-StrictMode -Version 'Latest'
#Requires -RunAsAdministrator

$containerID = docker ps -a -q --filter name=bitbucket
if ($containerID)
{
    docker rm $containerID --volumes --force
}

$imageID = docker images -q bitbucket-testinstance
if ($imageID)
{
    docker rmi $imageID
}
