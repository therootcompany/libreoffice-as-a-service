#!/bin/bash
# shellcheck disable=SC1090,SC1091
set -e
set -u

GIT_REF_NAME="${GIT_REF_NAME:-}"
GIT_REPO_ID="${GIT_REPO_ID:-EMPTY_REPO_ID}"
GIT_REPO_NAME="${GIT_REPO_NAME:-EMPTY_REPO_NAME}"

# See the Git Credentials Cheat Sheet
# https://coolaj86.com/articles/vanilla-devops-git-credentials-cheatsheet/
#git config --global url."https://api:${GITHUB_TOKEN}@github.com/savvi-legal/".insteadOf "https://github.com/savvi-legal/"
#git clone --branch "${GIT_REF_NAME}" "${GIT_CLONE_URL}" "${my_project}"

source ~/envs/"${GIT_REF_NAME}"/"${GIT_REPO_NAME}"/env 2> /dev/null ||
    source ~/envs/development/"${GIT_REPO_NAME}"/env 2> /dev/null ||
    true

export CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-}"
export GODADDY_API_KEY="${GODADDY_API_KEY:-}"
export GODADDY_API_SECRET="${GODADDY_API_SECRET:-}"
export DIGITALOCEAN_TOKEN="${DIGITALOCEAN_TOKEN:-}"

bash scripts/provision.sh \
    "${GIT_REPO_NAME}" "${GIT_REF_NAME}" "${DNS_SUBDOMAIN}" "${DNS_ZONE_NAME}"
