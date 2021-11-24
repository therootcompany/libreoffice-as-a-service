#!/bin/bash
set -e
set -u

BASE_URL="http://127.0.0.1:5227"

curl -fS "${BASE_URL}"'/api/convert/pdf?filename=Writing1.docx' \
    -H 'Content-Type: application/octet-stream' \
    --data-binary @'fixtures/Writing1.docx' \
    -o Writing1.pdf
