FROM openjdk:8-jdk-alpine3.9

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ENV JENKINS_HOME /var/jenkins_home
ENV JENKINS_HTTP_PORT 8080
ENV JENKINS_SLAVE_AGENT_PORT 50000

# ttf-dejavu for JVM issue: https://wiki.jenkins.io/display/JENKINS/Jenkins+got+java.awt.headless+problem
RUN apk add --no-cache git openssh-client curl unzip bash ttf-dejavu coreutils tini

RUN mkdir -p $JENKINS_HOME && \
    chown ${uid}:${gid} $JENKINS_HOME && \
    addgroup -g ${gid} ${group} && \
    adduser -h "$JENKINS_HOME" -u ${uid} -G ${group} -s /bin/bash -D ${user}

VOLUME $JENKINS_HOME

# `/usr/share/jenkins/ref/` contains all reference configuration we want
# to set on a fresh new installation. Use it to bundle additional plugins
# or config file with your custom jenkins Docker image.
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d

COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-agent-port.groovy

ENV JENKINS_VERSION 2.171
RUN curl -fsSL -o /usr/share/jenkins/jenkins.war https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war

ENV JENKINS_UC https://updates.jenkins.io
ENV JENKINS_UC_EXPERIMENTAL=https://updates.jenkins.io/experimental
ENV JENKINS_INCREMENTALS_REPO_MIRROR=https://repo.jenkins-ci.org/incrementals
RUN chown -R ${user} "$JENKINS_HOME" /usr/share/jenkins/ref

EXPOSE ${JENKINS_HTTP_PORT} ${JENKINS_SLAVE_AGENT_PORT}

ENV COPY_REFERENCE_FILE_LOG $JENKINS_HOME/copy_reference_file.log

USER ${user}

WORKDIR ${JENKINS_HOME}

COPY jenkins-support /usr/local/bin/jenkins-support
COPY jenkins.sh /usr/local/bin/jenkins.sh
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/jenkins.sh"]
