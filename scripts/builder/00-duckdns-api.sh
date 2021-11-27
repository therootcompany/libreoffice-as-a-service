#!/bin/bash
set -e
set -u

function _dd_api() {
    local my_params="${1}"

    curl -fsSL "https://www.duckdns.org/update?token=${DUCKDNS_API_TOKEN}${my_params}"
    # ?domains={YOURVALUE}&token={YOURVALUE}[&ip={YOURVALUE}][&ipv6={YOURVALUE}][&verbose=true][&clear=true]
}

function _dd_records_delete() {
    local my_zone="${1}"
    local my_sub="${2}"
    local my_type="${3}"

    _dd_api "&domains=${my_sub}&clear=true"
}

function _dd_record_get() {
    local my_zone="${1:-}"
    local my_sub="${2:-}"
    local my_type="${3:-}"

    # dig +short "${my_type}" "${my_sub}.${my_zone}" || true
    dig +trace "${my_type}" "${my_sub}.${my_zone}" | grep 'local-test.duckdns.org\.' | cut -f5 || true
}

function _dd_record_set() {
    local my_zone="${1}"
    local my_sub="${2}"
    local my_type="${3}"
    local my_record_value="${4}"

    if [[ "A" == "${my_type}" ]]; then
        echo _dd_api "&domains=${my_sub}&ip=${my_record_value}&ipv6="
    elif [[ "AAAA" == "${my_type}" ]]; then
        echo _dd_api "&domains=${my_sub}&ipv6=${my_record_value}"
    elif [[ "TXT" == "${my_type}" ]]; then
        echo _dd_api "&domains=${my_sub}&txt=${my_record_value}"
    else
        echo "Unsupported duckdns record type '${my_type}'."
        return 1
    fi
}

function dns_ipv46_set() {
    local my_sub="${1:-}"
    local my_zone="${2:-}"
    local my_ipv4="${3:-}"
    local my_ipv6="${4:-}"

    my_status="$(
        _dd_api "&domains=${my_sub}&ip=${my_ipv4}&ipv6=${my_ipv6}"
    )"
    if [[ "OK" != "${my_status}" ]]; then
        echo "failed to set '&domains=${my_sub}&ip=${my_ipv4}&ipv6=${my_ipv6}'"
        return 1
    fi

    if [[ -n ${my_ipv4} ]]; then
        echo "Set DNS record '${my_sub}.${my_zone}' 'A' '${my_ipv4}'"
    fi
    if [[ -n ${my_ipv6} ]]; then
        echo "Set DNS record '${my_sub}.${my_zone}' 'AAAA' '${my_ipv6}'"
    fi
}

function dns_ipv46_get() {
    local my_sub="${1:-}"
    local my_zone="${2:-}"

    local my_ipv4
    local my_ipv6

    my_ipv4="$(
        _dd_record_get "${my_zone}" "${my_sub}" "A"
    )"
    my_ipv6="$(
        _dd_record_get "${my_zone}" "${my_sub}" "AAAA"
    )"

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
    _dd_record_get "${my_zone}" "${my_sub}" "A"
    _dd_records_delete "${my_zone}" "${my_sub}" "A"
    echo "Deleted DNS record '${my_sub}.${my_zone}' 'A'"

    echo -n "[Backup] "
    _dd_record_get "${my_zone}" "${my_sub}" "AAAA"
    _dd_records_delete "${my_zone}" "${my_sub}" "AAAA"
    echo "Deleted DNS record '${my_sub}.${my_zone}' 'AAAA'"
}
