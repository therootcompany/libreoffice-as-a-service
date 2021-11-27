#!/bin/bash
# shellcheck disable=SC1090,SC1091
set -e
set -u

my_env="${1:-}"
my_domain="${2:-}"
my_zone="${3:-}"
my_project_name="${4:-}"

if [[ -z ${my_env} ]] ||
    [[ -z ${my_domain} ]] ||
    [[ -z ${my_zone} ]] ||
    [[ -z ${my_project_name} ]]; then
    echo ''
    echo 'Usage:'
    echo '    bash scripts/install.sh <env> <domain> <zone> <project-name>'
    echo ''
    echo 'Example:'
    echo "    bash scripts/install.sh 'dev' 'dev-123' 'example.com' 'foobar'"
    echo ''
    exit 1
fi

if [[ -z "$(command -v webi)" ]]; then
    curl https://webinstall.dev | bash
fi
export PATH="${HOME}/.local/bin:${PATH}"

if ! echo "${PATH}" | grep "${HOME}/bin:"; then
    mkdir -p ~/bin
    pathman add ~/bin
fi

if [[ -z "$(command -v fish)" ]]; then
    webi rg iterm2-utils
    export DEBIAN_FRONTEND=noninteractive
    if ! sudo apt-get install -y fish; then
        curl https://webinstall.dev/fish | bash
    fi
    sleep 2
    sudo rm -f /var/lib/apt/lists/lock
    sudo rm -f /var/lib/dpkg/lock
    sudo killall apt-get || true
fi

source .env 2> /dev/null || true
source ~/.env 2> /dev/null || true

CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-}"
export CLOUDFLARE_API_TOKEN
PORT="${PORT:-5227}"
export PORT

bash scripts/01-libreoffice.sh
bash scripts/01-caddy.sh
bash scripts/02-enable-site.sh "${my_domain}.${my_zone}" "${PORT}" "$(pwd)/public/"
if [[ ! -e node_modules ]]; then
    bash scripts/builder/01-build.sh
fi
bash scripts/03-app.sh "${my_domain}.${my_zone}" "${PORT}" "${my_project_name}"

pushd ~/srv/caddy
export PATH="${HOME}/bin:${PATH}"
caddy reload --config ./Caddyfile || sudo systemctl restart caddy
popd
