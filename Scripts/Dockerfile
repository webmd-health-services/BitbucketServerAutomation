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

FROM busybox:1.29 AS create-properties-file

ARG LICENSE
ARG USERNAME
ARG PASSWORD

RUN echo -e "setup.displayName=BitbucketServerAutomation Test Instance\n\
             setup.baseUrl=http://127.0.0.1:7990/\n\
             setup.license=${LICENSE}\n\
             setup.sysadmin.username=${USERNAME}\n\
             setup.sysadmin.password=${PASSWORD}\n\
             setup.sysadmin.displayName=Administrator\n\
             setup.sysadmin.emailAddress=admin@example.com\n\
             feature.auth.captcha=false" \
             > /bitbucket.properties

FROM atlassian/bitbucket-server:${VERSION}
COPY --from=create-properties-file /bitbucket.properties $BITBUCKET_HOME/bitbucket.properties