# Copyright 2017 The Kubernetes Authors.
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

# This Dockerfile will build an image that is configured
# to run Fluentd with an Elasticsearch plug-in and the
# provided configuration file.
# The image acts as an executable for the binary /usr/sbin/td-agent.
# Note that fluentd is run with root permssion to allow access to
# log files with root only access under /var/log/containers/*

# FROM debian:stretch-slim
FROM k8s.gcr.io/fluentd-elasticsearch:v2.2.0

ENV RBSPY_RELEASE="https://github.com/rbspy/rbspy/releases/download/v0.3.3/rbspy-v0.3.3-x86_64-unknown-linux-musl.tar.gz"

RUN apt-get install -y sudo vim tar wget \
    && clean-apt && \
    wget -O /tmp/rbspy.tar.gz "${RBSPY_RELEASE}" \
    && mkdir -p /opt/rbspy \
    && tar -xvzf /tmp/rbspy.tar.gz -C /opt/rbspy

# RUN https://github.com/rbspy/rbspy/releases/download/v0.3.3/rbspy-v0.3.3-x86_64-unknown-linux-musl.tar.gz

# RUN curl -sSf https://static.rust-lang.org/rustup.sh | sh

# git clone https://github.com/rbspy/rbspy
# cd rbspy
# cargo install
