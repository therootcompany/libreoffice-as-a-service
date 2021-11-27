#!/bin/bash
# shellcheck disable=SC1090,SC1091

set -e
set -u

if [[ -e .env ]]; then
    source ~/.env 2> /dev/null || true
fi
if [[ -e ../.env ]]; then
    source ~/.env 2> /dev/null || true
fi
if [[ -e ~/.env ]]; then
    source ~/.env 2> /dev/null || true
fi

source ./00-duckdns-api.sh

dns_ipv46_get "local-test" "duckdns.org"
dns_ipv46_set "local-test" "duckdns.org" "127.0.0.1" "::1"
dns_ipv46_get "local-test" "duckdns.org"
dns_ipv46_delete "local-test" "duckdns.org"
dns_ipv46_get "local-test" "duckdns.org"
