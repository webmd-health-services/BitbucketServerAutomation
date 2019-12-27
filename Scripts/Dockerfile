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

# The "VERSION" ARG is used in one of the FROM directives, therefore it *MUST*
# come before any FROM directive in this file
ARG VERSION

FROM atlassian/bitbucket-server:${VERSION}

ARG LICENSE
ARG USERNAME
ARG PASSWORD

ENV SETUP_DISPLAYNAME="BitbucketServerAutomation Test Instance"
ENV SETUP_BASEURL="http://127.0.0.1:7990/"
ENV SETUP_LICENSE="${LICENSE}"
ENV SETUP_SYSADMIN_USERNAME="${USERNAME}"
ENV SETUP_SYSADMIN_PASSWORD="${PASSWORD}"
ENV SETUP_SYSADMIN_DISPLAYNAME="Administrator"
ENV SETUP_SYSADMIN_EMAILADDRESS="admin@example.com"
