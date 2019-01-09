#!/bin/sh

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

set -ex

export NODE_NAME=${NODE_NAME:-${HOSTNAME}}
export NODE_MASTER=${NODE_MASTER:-true}
export NODE_DATA=${NODE_DATA:-true}
export HTTP_PORT=${HTTP_PORT:-9200}
export MEMORY_LOCK=${MEMORY_LOCK:-false}
export TRANSPORT_PORT=${TRANSPORT_PORT:-9300}
export MINIMUM_MASTER_NODES=${MINIMUM_MASTER_NODES:-2}
export DEFAULT_ES_JAVA_INITIAL_HEAP_SIZE=${DEFAULT_ES_JAVA_INITIAL_HEAP_SIZE:--Xms2g}
export DEFAULT_ES_JAVA_MAX_HEAP_SIZE=${DEFAULT_ES_JAVA_MAX_HEAP_SIZE:--Xmx2g}
export ELASTICSEARCH_HOME=${ELASTICSEARCH_HOME:-/usr/share/elasticsearch}

chown -R elasticsearch:elasticsearch /data

sed -i -e "s@\\-Xms2g@${DEFAULT_ES_JAVA_INITIAL_HEAP_SIZE}@g" $ELASTICSEARCH_HOME/config/jvm.options
sed -i -e "s@\\-Xmx2g@${DEFAULT_ES_JAVA_INITIAL_HEAP_SIZE}@g" $ELASTICSEARCH_HOME/config/jvm.options

./bin/elasticsearch_logging_discovery >> ./config/elasticsearch.yml
exec su elasticsearch -c ./bin/es-docker
