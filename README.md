# libreoffice-as-a-service (LaaS)

Convert documents through libreoffice (soffice) as a service

## Table of Contents

- Install, Configure, Run
- System Requirements for Linux
- How to test locally on macOS

## Run LaaS

### Download

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

### Install

```bash
bash scripts/install.sh
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

## System Requirements for Linux

- node v16+
- LibreOffice v6.4+

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

### How to test locally on macOS

- [Download LibreOffice for macOS](https://www.libreoffice.org/download/download/)

If you install LibreOffice to `~/Applications`, you can add `soffice` to your PATH, like so:

1. Temporarily add `soffice` to your `PATH`
   ```bash
   export PATH="/Applications/LibreOffice.app/Contents/MacOS:$PATH"
   ```
2. Install `pathman`
   ```bash
   curl https://webinstall.dev/pathman | bash
   export PATH="${HOME}.local/bin:${PATH}"
   ```
3. Permanently add `soffice` to your `PATH`
   ```bash
   pathman add /Applications/LibreOffice.app/Contents/MacOS
   ```

Now `node` will be able to find `soffice` and run it the same as on Linux.

**Note**: You can also use Webi to install `node`:

```bash
curl -L https://webinstall.dev/node@lts | bash
```
