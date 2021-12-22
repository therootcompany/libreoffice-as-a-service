#!/bin/bash
set -e
set -u

my_zone_id=""

function echo2() {
    echo >&2 "$@"
}

function _cf_api() {
    local my_method="${1}"
    local my_path="${2}"
    local my_json="${3:-}"

    my_debug="$(
        _cf_api_2 "${my_method}" "${my_path}" "${my_json}" | jq
    )"

    #echo2 "${my_method}" "${my_path}" "${my_debug}"
    echo "${my_debug}"
}

function _cf_api_2() {
    local my_method="${1}"
    local my_path="${2}"
    local my_json="${3:-}"

    #echo2 "curl -fsSL -X '${my_method}' 'https://api.cloudflare.com/client${my_path}' -H 'Authorization: Bearer ${CLOUDFLARE_API_TOKEN}'"

    if [[ -n ${my_json} ]]; then
        curl -fsSL -X "${my_method}" "https://api.cloudflare.com/client${my_path}" \
            -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "${my_json}"
    else
        curl -fsSL -X "${my_method}" "https://api.cloudflare.com/client${my_path}" \
            -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}"
    fi
}

function _cf_list_accounts() {
    _cf_api GET "/v4/accounts?page=1&per_page=20&direction=desc" |
        jq
}

function _cf_get_zone_id() {
    local my_zone="${1}"

    local my_zone_id

    my_zone_id="$(
        _cf_api GET "/v4/zones?name=${my_zone}&status=active&page=1&per_page=20&order=status&direction=desc&match=all" |
            jq -r '.result[0].id'
    )"
    echo "${my_zone_id}"
}

function _cf_get_ipv46() {
    local my_sub="${1}"
    local my_zone="${2}"

    local my_domain="${my_sub}.${my_zone}"
    local my_zone_id
    local my_cname
    local my_ipv4
    local my_ipv6

    my_zone_id="$(
        _cf_get_zone_id "${my_zone}"
    )"
    my_cname="$(
        _cf_api GET "/v4/zones/${my_zone_id}/dns_records?type=CNAME&name=${my_domain}&page=1&per_page=20&order=type&direction=desc&match=all" |
            jq -r '.result[0].content'
    )"
    if [[ "null" == "${my_cname}" ]]; then
        my_cname=""
    fi
    if [[ -n ${my_cname} ]]; then
        my_domain="${my_cname}"
    fi
    my_ipv4="$(
        _cf_api GET "/v4/zones/${my_zone_id}/dns_records?type=A&name=${my_domain}&page=1&per_page=20&order=type&direction=desc&match=all" |
            jq -r '.result[0].content'
    )"
    if [[ "null" == "${my_ipv4}" ]]; then
        my_ipv4=""
    fi
    my_ipv6="$(
        _cf_api GET "/v4/zones/${my_zone_id}/dns_records?type=AAAA&name=${my_domain}&page=1&per_page=20&order=type&direction=desc&match=all" |
            jq -r '.result[0].content'
    )"
    if [[ "null" == "${my_ipv6}" ]]; then
        my_ipv6=""
    fi
    if [[ -z ${my_ipv4} ]] && [[ -z ${my_ipv6} ]]; then
        echo ''
        return 0
    fi
    echo "${my_ipv4},${my_ipv6}"
}

function _cf_record_create() {
    local my_zone_id="${1}"
    local my_domain="${2}"
    local my_type="${3}"
    local my_new_content="${4}"

    _cf_api POST "/v4/zones/${my_zone_id}/dns_records" '{
        "name": "'"${my_domain}"'",
        "type": "'"${my_type}"'",
        "content": "'"${my_new_content}"'",
        "ttl": 600,
        "proxied": false
    }'
}

function _cf_record_patch() {
    local my_zone_id="${1}"
    local my_record_id="${2}"
    local my_new_content="${3}"

    _cf_api PATCH "/v4/zones/${my_zone_id}/dns_records/${my_record_id}" '{
        "content": "'"${my_new_content}"'"
    }'
}

function _cf_record_set() {
    local my_zone_id="${1}"
    local my_domain="${2}"
    local my_type="${3}"
    local my_new_content="${4}"

    local my_record_id

    # create or update
    my_record_id="$(
        _cf_api GET "/v4/zones/${my_zone_id}/dns_records?type=${my_type}&name=${my_domain}&page=1&per_page=20&order=type&direction=desc&match=all" |
            jq -r '.result[0].id'
    )"
    if [[ "null" == "${my_record_id}" ]]; then
        my_record_id=""
    fi
    if [[ -z ${my_record_id} ]]; then
        _cf_record_create \
            "${my_zone_id}" "${my_domain}" "${my_type}" "${my_new_content}" \
            > /dev/null
        echo "Created DNS record '${my_domain}' '${my_type}' '${my_new_content}'"
        return 0
    fi

    # TODO don't update when the record data is the same

    _cf_record_patch \
        "${my_zone_id}" "${my_record_id}" "${my_new_content}" \
        > /dev/null
    echo "Updated (${my_record_id}) '${my_domain}' '${my_type}' '${my_new_content}'"
}

function _cf_record_delete() {
    local my_zone_id="${1}"
    local my_domain="${2}"
    local my_type="${3}"

    local my_record_id

    my_record_id="$(
        _cf_api GET "/v4/zones/${my_zone_id}/dns_records?type=${my_type}&name=${my_domain}&page=1&per_page=20&order=type&direction=desc&match=all" |
            jq -r '.result[0].id'
    )"
    if [[ "null" == "${my_record_id}" ]]; then
        echo "No record to delete for '${my_domain}' '${my_type}'"
        return 0
    fi

    echo -n '[Backup] '
    _cf_api GET "/v4/zones/${my_zone_id}/dns_records/${my_record_id}"
    echo ''
    _cf_api DELETE "/v4/zones/${my_zone_id}/dns_records/${my_record_id}" > /dev/null
    echo "Deleted (${my_record_id}) '${my_domain}' '${my_type}'"
}

function _cf_set_ipv46() {
    local my_sub="${1}"
    local my_zone="${2}"
    local my_new_ipv4="${3}"
    local my_new_ipv6="${4}"

    local my_domain="${my_sub}.${my_zone}"
    local my_zone_id

    my_zone_id="$(
        _cf_get_zone_id "${my_zone}"
    )"

    if [[ -n ${my_new_ipv4} ]]; then
        _cf_record_set "${my_zone_id}" "${my_domain}" 'A' "${my_new_ipv4}"
    fi
    if [[ -n ${my_new_ipv6} ]]; then
        _cf_record_set "${my_zone_id}" "${my_domain}" 'AAAA' "${my_new_ipv6}"
    fi
}

function _cf_clear_ipv46() {
    local my_sub="${1}"
    local my_zone="${2}"

    local my_domain="${my_sub}.${my_zone}"
    local my_zone_id

    my_zone_id="$(
        _cf_get_zone_id "${my_zone}"
    )"

    _cf_record_delete "${my_zone_id}" "${my_domain}" 'A'
    _cf_record_delete "${my_zone_id}" "${my_domain}" 'AAAA'
}

function dns_ipv46_get() {
    local my_sub="${1}"
    local my_zone="${2}"

    # ex: 127.0.0.1,::1
    _cf_get_ipv46 "${my_sub}" "${my_zone}"
}

function dns_ipv46_set() {
    local my_sub="${1}"
    local my_zone="${2}"
    local my_ipv4="${3}"
    local my_ipv6="${4}"

    _cf_set_ipv46 "${my_sub}" "${my_zone}" "${my_ipv4}" "${my_ipv6}"
}

function dns_ipv46_delete() {
    local my_sub="${1}"
    local my_zone="${2}"

    _cf_clear_ipv46 "${my_sub}" "${my_zone}"
}
