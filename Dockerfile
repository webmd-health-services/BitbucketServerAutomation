
FROM atlassian/bitbucket:8.19.27

ARG LICENSE
ARG USERNAME
ARG PASSWORD

# RUN BB_PROPS_PATH=/var/atlassian/application-data/bitbucket/shared/bitbucket.properties && \
# RUN mkdir -p /var/atlassian/application-data/bitbucket/shared
# RUN chmod 0777 /var/atlassian/application-data/bitbucket/shared
# RUN echo setup.displayName=BitbucketServerAutomation Test Instance > /var/atlassian/application-data/bitbucket/shared/bitbucket.properties
# RUN echo setup.baseUrl=http://127.0.0.1:7990/ >> /var/atlassian/application-data/bitbucket/shared/bitbucket.properties
# RUN echo setup.license=${LICENSE} >> /var/atlassian/application-data/bitbucket/shared/bitbucket.properties
# RUN echo setup.sysadmin.username=${USERNAME} >> /var/atlassian/application-data/bitbucket/shared/bitbucket.properties
# RUN echo setup.sysadmin.password=${PASSWORD} >> /var/atlassian/application-data/bitbucket/shared/bitbucket.properties
# RUN echo setup.sysadmin.displayName=Administrator >> /var/atlassian/application-data/bitbucket/shared/bitbucket.properties
# RUN echo setup.sysadmin.emailAddress=admin@example.com >> /var/atlassian/application-data/bitbucket/shared/bitbucket.properties
# RUN echo jdbc.driver=org.postgresql.Driver >> /var/atlassian/application-data/bitbucket/shared/bitbucket.properties
# RUN echo jdbc.url=jdbc:postgresql://localhost:5432/bitbucket >> /var/atlassian/application-data/bitbucket/shared/bitbucket.properties
# RUN echo jdbc.user=bitbucket >> /var/atlassian/application-data/bitbucket/shared/bitbucket.properties
# RUN echo jdbc.password=bitbucket >> /var/atlassian/application-data/bitbucket/shared/bitbucket.properties

ENV SETUP_DISPLAYNAME="BitbucketServerAutomation Test Instance"
ENV SETUP_BASEURL="http://127.0.0.1:7990/"
ENV SETUP_LICENSE="${LICENSE}"
ENV SETUP_SYSADMIN_USERNAME="${USERNAME}"
ENV SETUP_SYSADMIN_PASSWORD="${PASSWORD}"
ENV SETUP_SYSADMIN_DISPLAYNAME="Administrator"
ENV SETUP_SYSADMIN_EMAILADDRESS="admin@example.com"
# ENV JDBC_DRIVER=
# ENV JDBC_URL=
# ENV JDBC_USER=
# ENV JDBC_PASSWORD=
