#!/bin/bash
set -e
set -u

function do_api() {
    local my_method="${1}"
    local my_path="${2}"
    local my_json="${3:-}"

    if [[ -n ${my_json} ]]; then
        curl -fsSL -X "${my_method}" "https://api.digitalocean.com${my_path}" \
            -H "Authorization: Bearer ${DIGITALOCEAN_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "${my_json}"
    else
        curl -fsSL -X "${my_method}" "https://api.digitalocean.com${my_path}" \
            -H "Authorization: Bearer ${DIGITALOCEAN_TOKEN}"
    fi
}
