#!/bin/bash
# shellcheck disable=SC1090,SC1091
set -e
set -u

source scripts/builder/00-digitalocean-api.sh

my_sub="${1}"
my_zone="${2}"
my_project="${3:-}"
my_dns_api="${4:-}"
my_ipv4=""
my_ipv6=""

source "${my_dns_api}"

function do_create() {
    # "ssh_keys": [ { id, name, public_key, fingerprint } ]
    echo "Getting SSH Keys"
    my_keys="$(do_api GET "/v2/account/keys" | jq '[.ssh_keys[].id]')"

    # TODO attach volumes
    echo "Creating droplet"
    my_droplet="$(
        do_api POST "/v2/droplets" '{
          "name": '"\"${my_sub}.${my_zone}\""',
          "region": "nyc3",
          "size": "s-1vcpu-1gb",
          "image": "ubuntu-20-04-x64",
          "ssh_keys": '"${my_keys}"',
          "backups": true,
          "ipv6": true,
          "monitoring": true,
          "user_data": "N/A",
          "with_droplet_agent": true,
          "volumes": [],
          "tags": [ "delete-me" ]
        }' | jq '.droplet.id'
    )"

    if [[ -n ${my_project} ]]; then
        # assign resource to project
        echo "Reassigning Droplet ${my_droplet} to Project"
        do_api POST "/v2/projects/${my_project}/resources" '{
      "resources": [
        "do:droplet:'"${my_droplet}"'"
      ]
    }'
    fi

    my_status=""
    while true; do
        echo 'checking for IP addresses...'
        my_stats="$(
            do_api GET "/v2/droplets/${my_droplet}" |
                jq '{
                    status: .droplet.status,
                    ipv4: .droplet.networks.v4[] | select(.type == "public") | .ip_address,
                    ipv6: .droplet.networks.v6[] | select(.type == "public") | .ip_address
                }'
        )"
        my_ipv4="$(echo "${my_stats}" | jq -r '.ipv4')"
        my_ipv6="$(echo "${my_stats}" | jq -r '.ipv6')"

        if [[ -n ${my_ipv4} ]]; then
            break
        fi
        sleep 2
    done

    if [[ -n "$(command -v dns_ipv46_set)" ]]; then
        dns_ipv46_set "${my_sub}" "${my_zone}" "${my_ipv4}" "${my_ipv6}"
    fi

    while true; do
        echo 'checking for "active" status...'
        my_status="$(
            do_api GET "/v2/droplets/${my_droplet}" |
                jq -r '.droplet.status'
        )"
        echo "Status: '${my_status}'"
        if [[ "active" == "$my_status" ]]; then
            break
        fi
        sleep 10
    done

    my_count=1
    while [[ ${my_count} -lt 10 ]]; do
        echo "($my_count) testing SSH connection..."
        my_count=$((my_count + 1))
        if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=1 -o ConnectionAttempts=1 \
            "root@${my_ipv4}" "echo hello"; then
            break
        fi
        sleep 10
    done

    echo "attempting basic server setup..."
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "root@${my_ipv4}" "
        curl -fsSL https://webinstall.dev/ssh-adduser | bash
        curl -fsSL https://webinstall.dev/vps-addswap | bash
        apt-get -y update
        sleep 2
        rm /var/lib/apt/lists/lock
        rm -f /var/lib/dpkg/lock
        killall apt-get || true
    "
}

function main() {
    #my_date="$(date '+%FT%H:%M:%S')"

    if [[ -n "$(command -v dns_ipv46_get)" ]]; then
        echo "Checking for '${my_sub}.${my_zone}' ..."
        local my_ipv46
        my_ipv46="$(
            dns_ipv46_get "${my_sub}" "${my_zone}"
        )"
        if [[ -n ${my_ipv46} ]]; then
            my_ipv4="$(
                echo "${my_ipv46}" | cut -d',' -f1
            )"
            my_ipv6="$(
                echo "${my_ipv46}" | cut -d',' -f2
            )"
        fi
    fi

    if [[ -z ${my_ipv4} ]] && [[ -z ${my_ipv6} ]]; then
        echo "Provisioning new VPS ..."
        do_create
    else
        echo -n "Using existing VPS at"
        if [[ -n ${my_ipv4} ]]; then
            echo -n " ${my_ipv4}"
        fi
        if [[ -n ${my_ipv6} ]]; then
            echo -n " ${my_ipv6}"
        fi
        echo " ..."
    fi
}

main "$@"

#ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "app@${my_sub}.${my_zone}"
