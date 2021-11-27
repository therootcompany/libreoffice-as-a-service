#!/bin/bash
#shellcheck disable=SC2143
set -e
set -u

if [[ -z "$(command -v setcap-netbind)" ]]; then
    webi setcap-netbind
fi

export PATH="${HOME}/bin:${PATH}"
if [[ -z "$(command -v caddy)" ]]; then
    echo "Installing caddy."
    my_caddy_dl='https://caddyserver.com/api/download?os=linux&arch=amd64&p=github.com%2Fcaddy-dns%2Fcloudflare&p=github.com%2Fcaddy-dns%2Fduckdns&idempotency=54392291884254'

    mkdir -p ~/bin
    curl -L "${my_caddy_dl}" > ~/bin/caddy.part
    mv ~/bin/caddy.part ~/bin/caddy
    chmod a+x ~/bin/caddy
fi
setcap-netbind caddy

if [[ -z "$(command -v serviceman)" ]]; then
    webi serviceman
fi

mkdir -p ~/srv/caddy/sites-enabled
if [[ ! -e ~/srv/caddy/Caddyfile ]]; then
    echo "Creating Caddyfile ..."
    echo 'import sites-enabled/*' > ~/srv/caddy/Caddyfile
fi

if [[ ! -e ~/srv/caddy/.env ]]; then
    touch ~/srv/caddy/.env
fi
if [[ -n ${CLOUDFLARE_API_TOKEN} ]]; then
    echo "Copying .env for Caddy ..."
    echo "CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN}" > ~/srv/caddy/.env
fi

if ! serviceman list --system | grep -i -q caddy > /dev/null &&
    ! serviceman list --user | grep -i -q caddy > /dev/null; then
    pushd ~/srv/caddy/ > /dev/null
    echo "Starting Caddy as a system service ..."
    sudo env PATH="$PATH" \
        serviceman add \
        --name caddy \
        --system \
        --username "$(whoami)" \
        --path "$PATH" \
        -- \
        caddy run --envfile ./.env --config ./Caddyfile
    popd > /dev/null
fi
