#!/usr/bin/env bash

set -x

# source: https://botleg.com/stories/log-management-of-docker-swarm-with-elk-stack/
export DNS_DOMAIN=${DNS_DOMAIN:-scarlettlab.com}
export ES_IP="elasticsearch.${DNS_DOMAIN}"
export URL_BASE="http://${ES_IP}/.kibana"

CreateElasticsearchIndex() {
    # Run this command to create a Logstash index pattern:
    curl -XPUT -D- ${URL_BASE}'/index-pattern/logstash-*' \
        -H 'Content-Type: application/json' \
        -d '{"title" : "logstash-*", "timeFieldName": "@timestamp", "notExpandable": true}'

    # This command will mark the Logstash index pattern as the default index pattern:
    curl -XPUT -D- ${URL_BASE}'/config/5.6.2' \
        -H 'Content-Type: application/json' \
        -d '{"defaultIndex": "logstash-*"}'
}


until CreateElasticsearchIndex; do
  echo 'Creating Elasticsearch Index...'
  sleep 1
done
echo 'Done!'

wait
