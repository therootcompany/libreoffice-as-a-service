#!/bin/bash
set -e
set -u

my_api_domain="${1}"
my_api_port="${2}"
my_app_dir="${3}"

my_tls_config=''
if [[ -e ~/srv/caddy/.env ]] && grep 'CLOUDFLARE_API_TOKEN' ~/srv/caddy/.env; then
    my_tls_config='tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    }'
#elif grep 'GODADDY' ~/srv/caddy/.env; then
#    my_tls_config='tls {
#        dns godaddy {env.GODADDY_API_KEY} {env.GODADDY_API_SECRET}
#    }'
fi

mkdir -p ~/srv/caddy/sites-enabled
cat > ~/srv/caddy/sites-enabled/"${my_api_domain}".Caddyfile << EOF
${my_api_domain} {
    log {
        output stdout
        format console
    }
    ${my_tls_config}
    @notPandadoc {
        not path /api/box/*
    }
    encode @notPandadoc gzip zstd
    reverse_proxy /api/* localhost:${my_api_port}
    reverse_proxy /.well-known/* localhost:${my_api_port}
    @notApi {
        file {
            try_files {path} {path}/ /index.html
        }
        not path /api/*
        not path /.well-known/*
    }
    route {
      rewrite @notApi {http.matchers.file.relative}
    }
    root * ${my_app_dir}
    file_server
}
EOF
