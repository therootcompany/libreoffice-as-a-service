#!/bin/bash
set -e
set -u

function _gd_api() {
    local my_method="${1}"
    local my_path="${2}"
    local my_json="${3:-}"

    if [[ -n ${my_json} ]]; then
        curl -fsSL -X "${my_method}" "https://api.godaddy.com${my_path}" \
            -H "Authorization: sso-key ${GODADDY_API_KEY}:${GODADDY_API_SECRET}" \
            -H "Content-Type: application/json" \
            -d "${my_json}"
    else
        curl -fsSL -X "${my_method}" "https://api.godaddy.com${my_path}" \
            -H "Authorization: sso-key ${GODADDY_API_KEY}:${GODADDY_API_SECRET}"
    fi
}

function _gd_records_delete() {
    local my_zone="${1}"
    local my_sub="${2}"
    local my_type="${3}"

    _gd_api DELETE "/v1/domains/${my_zone}/records/${my_type}/${my_sub}"
}

function _gd_record_get() {
    local my_zone="${1:-}"
    local my_sub="${2:-}"
    local my_type="${3:-}"

    _gd_api GET "/v1/domains/${my_zone}/records/${my_type}/${my_sub}"
}

function _gd_record_set() {
    local my_zone="${1}"
    local my_sub="${2}"
    local my_type="${3}"
    local my_record_value="${4}"

    _gd_api PUT "/v1/domains/${my_zone}/records/${my_type}/${my_sub}" '[
        {
            "data": "'"${my_record_value}"'",
            "ttl": 600
        }
    ]'
}

function dns_ipv46_set() {
    local my_sub="${1:-}"
    local my_zone="${2:-}"
    local my_ipv4="${3:-}"
    local my_ipv6="${4:-}"

    if [[ -n ${my_ipv4} ]]; then
        _gd_record_set \
            "${my_zone}" "${my_sub}" 'A' "${my_ipv4}" \
            > /dev/null
        echo "Set DNS record '${my_sub}.${my_zone}' 'A' '${my_ipv4}'"
    fi
    if [[ -n ${my_ipv6} ]]; then
        _gd_record_set \
            "${my_zone}" "${my_sub}" 'AAAA' "${my_ipv6}" \
            > /dev/null
        echo "Set DNS record '${my_sub}.${my_zone}' 'AAAA' '${my_ipv6}'"
    fi
}

function dns_ipv46_get() {
    local my_sub="${1:-}"
    local my_zone="${2:-}"

    local my_ipv4_json
    local my_ipv4
    local my_ipv6_json
    local my_ipv6

    my_ipv4_json="$(
        _gd_record_get "${my_zone}" "${my_sub}" "A"
    )"
    if [[ -n ${my_ipv4_json} ]]; then
        my_ipv4="$(
            echo "${my_ipv4_json}" |
                jq -r '.[0].data'
        )"
        if [[ "null" == "${my_ipv4}" ]]; then
            my_ipv4=""
        fi
    fi

    my_ipv6_json="$(
        _gd_record_get "${my_zone}" "${my_sub}" "AAAA"
    )"
    if [[ -n ${my_ipv6_json} ]]; then
        my_ipv6="$(
            echo "${my_ipv6_json}" |
                jq -r '.[0].data'
        )"
        if [[ "null" == "${my_ipv6}" ]]; then
            my_ipv6=""
        fi
    fi

    if [[ -z ${my_ipv4} ]] && [[ -z ${my_ipv4} ]]; then
        echo ''
        return 0
    fi
    echo "${my_ipv4},${my_ipv6}"
}

function dns_ipv46_delete() {
    local my_sub="${1:-}"
    local my_zone="${2:-}"

    echo -n "[Backup] "
    _gd_record_get "${my_zone}" "${my_sub}" "A"
    _gd_records_delete "${my_zone}" "${my_sub}" "A"
    echo "Deleted DNS record '${my_sub}.${my_zone}' 'A'"

    echo -n "[Backup] "
    _gd_record_get "${my_zone}" "${my_sub}" "AAAA"
    _gd_records_delete "${my_zone}" "${my_sub}" "AAAA"
    echo "Deleted DNS record '${my_sub}.${my_zone}' 'AAAA'"
}

#dns_ipv46_set "local-test" "savvy.legal" "127.0.0.1" "::1"
#dns_ipv46_get "local-test" "savvy.legal"
#dns_ipv46_delete "local-test" "savvy.legal"
