#!/bin/bash
set -e
set -u

my_version="6-4"

if [[ -z "$(command -v libreoffice)" ]]; then
    # TODO make this a microservice
    # TODO investigate unoconv, see https://askubuntu.com/a/398499
    export DEBIAN_FRONTEND=noninteractive

    sudo add-apt-repository -y ppa:libreoffice/ppa
    sleep 2
    sudo rm -f /var/lib/apt/lists/lock
    sudo rm -f /var/lib/dpkg/lock
    sudo killall apt-get || true

    sudo add-apt-repository -y ppa:libreoffice/libreoffice-"${my_version}"
    sleep 2
    sudo rm -f /var/lib/apt/lists/lock
    sudo rm -f /var/lib/dpkg/lock
    sudo killall apt-get || true

    sudo apt-get -y update
    sleep 2
    sudo rm -f /var/lib/apt/lists/lock
    sudo rm -f /var/lib/dpkg/lock
    sudo killall apt-get || true

    sudo apt-get install -y libreoffice
    sleep 2
    sudo rm -f /var/lib/apt/lists/lock
    sudo rm -f /var/lib/dpkg/lock
    sudo killall apt-get || true
fi
