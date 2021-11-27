#!/bin/bash
# shellcheck disable=SC1090,SC1091

if [[ -e .env ]]; then
    source ~/.env 2> /dev/null || true
fi
if [[ -e ../.env ]]; then
    source ~/.env 2> /dev/null || true
fi
if [[ -e ~/.env ]]; then
    source ~/.env 2> /dev/null || true
fi

source ./00-godaddy-api.sh

dns_ipv46_get "local-test" "example.net"
dns_ipv46_set "local-test" "example.net" "127.0.0.1" "::1"
dns_ipv46_get "local-test" "example.net"
dns_ipv46_delete "local-test" "example.net"
dns_ipv46_get "local-test" "example.net"
