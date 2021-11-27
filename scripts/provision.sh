#!/bin/bash
# shellcheck disable=SC1090,SC1091
set -e
set -u

GIT_REPO_NAME="${GIT_REPO_NAME:-"${1}"}"
GIT_REF_NAME="${GIT_REF_NAME:-"${2}"}"
my_env="${2:-development}"
DNS_RECORD_NAME="${DNS_RECORD_NAME:-"${3}"}"
DNS_ZONE_NAME="${DNS_ZONE_NAME:-"${4}"}"
LAAS_API_TOKEN="${LAAS_API_TOKEN:-"$(openssl rand -hex 10)"}"

if [[ -z ${GIT_REPO_NAME} ]] ||
    [[ -z ${GIT_REF_NAME} ]] ||
    [[ -z ${DNS_RECORD_NAME} ]] ||
    [[ -z ${DNS_ZONE_NAME} ]] ||
    [[ -z ${LAAS_API_TOKEN} ]]; then
    echo ''
    echo 'Usage (with ENVs):'
    echo ''
    echo '    export GIT_REPO_NAME=foobar'
    echo '    export GIT_REF_NAME=development'
    echo '    export DNS_RECORD_NAME=foobar'
    echo '    export DNS_ZONE_NAME=example.com'
    echo '    export LAAS_API_TOKEN="$(openssl rand -hex 10)"'
    echo '    bash scripts/provision.sh <env> <domain> <zone> <project-name>'
    echo ''
    echo 'Usage (with arguments):'
    echo '    bash scripts/provision.sh <project-name> <branch> <domain> <zone>'
    echo "    bash scripts/provision.sh 'foobar' 'dev' 'dev-123' 'example.com'"
    echo ''
    exit 1
fi

function check_builder_deps() {
    if [[ -z "$(command -v webi)" ]]; then
        curl https://webinstall.dev | bash
    fi
    export PATH="$HOME/.local/bin:${PATH}"
}

function build() {
    bash scripts/builder/01-build.sh
}

function source_all() {
    local my_env="${1}"

    source ".env.${my_env}" 2> /dev/null || true
    #shellcheck disable=SC2153
    source ~/envs/"${my_env}"/"${GIT_REPO_NAME}"/env 2> /dev/null || true
    source .env 2> /dev/null || true
    source ../.env 2> /dev/null || true
    source ~/.env 2> /dev/null || true
}

function deploy() {
    local my_env="${1}"
    local my_domain="${2}"
    local my_zone="${3}"
    local my_do_project="${4:-}"
    local my_dns_api="${5}"

    bash ./scripts/builder/01-provision-vps.sh \
        "${my_domain}" "${my_zone}" "${my_do_project}" "${my_dns_api}"

    local my_hostname="app@${my_domain}.${my_zone}"
    #ssh-keygen -f ~/.ssh/known_hosts -R "${my_hostname}"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        "${my_hostname}" 'mkdir -p ~/srv/'

    #shellcheck disable=SC2153
    rsync -e 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' \
        -av --delete --inplace --exclude=.git \
        ./ "${my_hostname}":~/srv/"${GIT_REPO_NAME}"/

    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        "${my_hostname}" "
            source ~/.config/envman/load.sh
            rm -f ~/.env
            echo 'CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN:-}' >> ./.env
            echo 'GODADDY_API_KEY=${GODADDY_API_KEY:-}' >> ./.env
            echo 'GODADDY_API_SECRET=${GODADDY_API_SECRET:-}' >> ./.env
            pushd ~/srv/'${GIT_REPO_NAME}'/
            echo 'PORT=5227' >> ./.env
            echo 'API_TOKEN=${LAAS_API_TOKEN:-}' >> ./.env
            bash scripts/install.sh '${my_env}' '${my_domain}' '${my_zone}' '${GIT_REPO_NAME}'
            popd
        "
}

check_builder_deps
build

export DIGITALOCEAN_TOKEN

if [[ "production" == "${GIT_REF_NAME}" ]]; then

    echo "Deploying production..."
    source_all 'production'
    export CLOUDFLARE_API_TOKEN
    deploy production "${DNS_RECORD_NAME}" "${DNS_ZONE_NAME}" "${DIGITALOCEAN_PROJECT:-}" "${DNS_PRODUCTION_API}"

elif [[ "development" == "${GIT_REF_NAME}" ]]; then

    echo "Deploying development..."
    source_all 'development'
    export CLOUDFLARE_API_TOKEN=""
    export GODADDY_API_KEY
    export GODADDY_API_SECRET
    deploy dev "${DNS_RECORD_NAME}" "${DNS_ZONE_NAME}" "${DIGITALOCEAN_PROJECT:-}" "${DNS_DEVELOPMENT_API}"

else

    echo "Nothing to do for '${GIT_REF_NAME}'."

fi
