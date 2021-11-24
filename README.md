# libreoffice-as-a-service (LaaS)

Convert documents through libreoffice (soffice) as a service

## Table of Contents

- Install, Configure, Run
- System Requirements for Linux
- How to test locally on macOS

## Run with Node

### Install

```bash
git clone git@github.com:savvi-legal/libreoffice-as-a-service.git
pushd ./libreoffice-as-a-service/
```

### Configure

```bash
echo 'PORT=5227' >> .env
```

<!--
```bash
rsync -avHP example.env .env
echo "API_TOKEN=$(openssl rand -hex 8)" >> .env
```
-->

### Run

```bash
npm ci --only=production
npm run start
```

## Demo Page

```bash
# LaaS => 5227
open http://127.0.0.1:5227/
```

## Demo cURL

```bash
BASE_URL="http://127.0.0.1:5227"

curl -fS "${BASE_URL}"'/api/convert/pdf?filename=Writing1.docx' \
    -H 'Content-Type: application/octet-stream' \
    --data-binary @'fixtures/Writing1.docx' \
    -o Writing1.pdf
```

**Important**: `-d` is NOT the same as `--data-binary`.

## System Requirements

- LibreOffice
- node

```bash
if [[ -z "$(command -v node)" ]]; then
    curl -fsSL https://webinstall.dev/node@lts | bash
fi

if [[ -z "$(command -v libreoffice)" ]]; then
    sudo add-apt-repository -y ppa:libreoffice/ppa
    sudo add-apt-repository -y ppa:libreoffice/libreoffice-6-4
    sudo apt-get -y update
    sudo apt-get install -y libreoffice
fi
```

### Users of macOS

[Download LibreOffice for macOS](https://www.libreoffice.org/download/download/)

If you install LibreOffice to `~/Applications`, you can add `soffice` to your path, like so:

```bash
# Install pathman
curl https://webinstall.dev/pathman | bash
export PATH="${HOME}.local/bin:${PATH}"

# Permanently (and in the current session) add soffice to PATH
pathman add /Applications/LibreOffice.app/Contents/MacOS
export PATH="/Applications/LibreOffice.app/Contents/MacOS:$PATH"
```
