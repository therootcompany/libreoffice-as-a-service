#!/bin/bash
set -e
set -u

if [[ -z "$(command -v node)" ]]; then
    curl https://webinstall.dev/node@16 | bash
fi
export PATH="$HOME/.local/opt/node/bin:${PATH}"

npm ci --only=production
