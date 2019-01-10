#!/usr/bin/env bash

# set -x

# source: https://botleg.com/stories/log-management-of-docker-swarm-with-elk-stack/

export DNS_DOMAIN=${DNS_DOMAIN:-scarlettlab.com}
export DNS_KIBANA="kibana.${DNS_DOMAIN}"
export URL_BASE="http://${DNS_KIBANA}/api/kibana/dashboards/import?force=true"

ImportKibanaDashboard() {
    # Run this command to create a Logstash index pattern:
    curl -v -s --connect-timeout 60 \
    --max-time 60 -XPOST ${URL_BASE} \
    -H 'kbn-xsrf:true' -H 'Content-type:application/json' \
    -d -D- @../fixtures/kibana/k8s-fluentd-elasticsearch.json

}


until ImportKibanaDashboard; do
  echo 'Creating Kibana Dashboard...'
  sleep 1
done
echo 'Done!'

wait




