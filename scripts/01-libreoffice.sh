#!/bin/bash
set -e
set -u

my_version="6-4"

if [[ -z "$(command -v libreoffice)" ]]; then
    # TODO make this a microservice
    # TODO investigate unoconv, see https://askubuntu.com/a/398499
    export DEBIAN_FRONTEND=noninteractive
    sudo add-apt-repository -y ppa:libreoffice/ppa
    sudo add-apt-repository -y ppa:libreoffice/libreoffice-"${my_version}"
    sudo apt-get -y update
    sudo apt-get install -y libreoffice
fi
