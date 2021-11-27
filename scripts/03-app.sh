#!/bin/bash
set -e
set -u

#my_domain="${1}"
#my_port="${2}"
my_servicename="${3}"

if [[ -z "$(command -v watchexec)" ]]; then
    webi watchexec
fi

if [[ -z "$(command -v node)" ]]; then
    webi node@16
fi
export PATH="$HOME/.local/opt/node/bin:${PATH}"

if [[ "development" == "${NODE_ENV:-}" ]]; then
    # stop watchexec first in development environments
    if ! sudo systemctl status "${my_servicename}" | grep 'could not'; then
        sudo systemctl stop "${my_servicename}" || true
    fi
    sudo env PATH="${PATH}" \
        serviceman add --name "${my_servicename}" --system \
        --username "$(whoami)" --path "${PATH}" -- \
        watchexec -r -e js -- -- \
        npm run start # -- --port "${my_port}"
else
    sudo env PATH="${PATH}" \
        serviceman add --name "${my_servicename}" --system \
        --username "$(whoami)" --path "${PATH}" -- \
        npm run start # -- --port "${my_port}"
fi
