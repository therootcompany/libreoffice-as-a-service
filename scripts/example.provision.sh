#!/bin/bash
set -e
set -u

bash scripts/provision.sh \
    "libreoffice-as-a-service" "development" dev-laas example.net
