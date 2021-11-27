#!/bin/bash
set -e
set -u

sudo systemctl stop caddy || true
sudo rm -f /etc/systemd/system/caddy.service
rm -rf ~/srv/caddy
rm -rf ~/.config/caddy

sudo systemctl stop libreoffice-as-a-service || true
sudo rm -f /etc/systemd/system/libreoffice-as-a-service.service
#rm -rf ~/srv/libreoffice-as-a-service

rm -rf ~/.local
