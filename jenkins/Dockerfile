FROM jenkins/jenkins:lts
MAINTAINER TonyDark Jarvis <jarvis@theblacktonystark.com>

LABEL maintainer="jarvis@theblacktonystark.com"

# Ballerina runtime distribution filename.
ARG BUILD_DATE
ARG VCS_REF
ARG BUILD_VERSION

# Labels.
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="bossjones/jenkins"
LABEL org.label-schema.description="Jenkins"
LABEL org.label-schema.url="https://jenkins.io/"
LABEL org.label-schema.vcs-url="https://github.com/jenkinsci/docker/blob/master/Dockerfile"
LABEL org.label-schema.vcs-ref=$VCS_REF
LABEL org.label-schema.vendor="TonyDark Industries"
LABEL org.label-schema.version=$BUILD_VERSION
LABEL org.label-schema.docker.cmd="docker run -p 8080:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home bossjones/jenkins:latest"

USER root

ENV DOCKER_VERSION=docker-ce_17.03.0~ce-0~debian-stretch_amd64.deb
ENV KUBERNETES_VERSION=v1.13.1

# Install prerequisites for Docker
RUN apt-get update && apt-get install -y sudo maven iptables libsystemd-dev libsystemd0 init-system-helpers libapparmor1 libltdl7 libseccomp2 libdevmapper1.02.1 && rm -rf /var/lib/apt/lists/*
# Set up Docker

RUN wget https://download.docker.com/linux/debian/dists/stretch/pool/stable/amd64/$DOCKER_VERSION
RUN dpkg -i $DOCKER_VERSION
# Set up Kubernetes
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$KUBERNETES_VERSION/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl; chown ${user}:${user} ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl
# Configure access to the Kubernetes Cluster
# ADD ../../conf/config ~/.kube
# ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/jenkins.sh"]

# SOURCE: https://www.blazemeter.com/blog/how-to-setup-scalable-jenkins-on-top-of-a-kubernetes-cluster
# Distributed Builds plugins
RUN /usr/local/bin/install-plugins.sh ssh-slaves

# install Notifications and Publishing plugins
RUN /usr/local/bin/install-plugins.sh email-ext
RUN /usr/local/bin/install-plugins.sh mailer
RUN /usr/local/bin/install-plugins.sh slack

# Artifacts
RUN /usr/local/bin/install-plugins.sh htmlpublisher

# UI
RUN /usr/local/bin/install-plugins.sh greenballs
RUN /usr/local/bin/install-plugins.sh simple-theme-plugin

# Scaling
RUN /usr/local/bin/install-plugins.sh kubernetes

USER jenkins



# from jenkins/jenkins:2.60.1

# # Distributed Builds plugins
# RUN /usr/local/bin/install-plugins.sh ssh-slaves

# # install Notifications and Publishing plugins
# RUN /usr/local/bin/install-plugins.sh email-ext
# RUN /usr/local/bin/install-plugins.sh mailer
# RUN /usr/local/bin/install-plugins.sh slack

# # Artifacts
# RUN /usr/local/bin/install-plugins.sh htmlpublisher

# # UI
# RUN /usr/local/bin/install-plugins.sh greenballs
# RUN /usr/local/bin/install-plugins.sh simple-theme-plugin

# # Scaling
# RUN /usr/local/bin/install-plugins.sh kubernetes

# # install Maven
# USER root
# RUN apt-get update && apt-get install -y maven
# USER jenkins
