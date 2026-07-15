#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CERT_DIR="${ROOT_DIR}/.local/certs"
CERT_FILE="${CERT_DIR}/canopy.rpc.pem"
KEY_FILE="${CERT_DIR}/canopy.rpc-key.pem"

mkdir -p "${CERT_DIR}"

if command -v mkcert >/dev/null 2>&1; then
  TRUST_STORES=system mkcert -install
  TRUST_STORES=system mkcert \
    -cert-file "${CERT_FILE}" \
    -key-file "${KEY_FILE}" \
    canopy.rpc localhost 127.0.0.1 ::1
  cat <<EOF
Generated a locally trusted certificate with mkcert:
  ${CERT_FILE}
  ${KEY_FILE}

Next steps:
  1. Add "127.0.0.1 canopy.rpc" to /etc/hosts
  2. Start Canopy RPC on http://127.0.0.1:50002
  3. Run: make run/https-rpc-proxy
  4. Use: https://canopy.rpc:8443/v1/eth
EOF
  exit 0
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "mkcert and openssl are both unavailable. Install one of them first." >&2
  exit 1
fi

openssl req \
  -x509 \
  -nodes \
  -newkey rsa:2048 \
  -sha256 \
  -days 825 \
  -keyout "${KEY_FILE}" \
  -out "${CERT_FILE}" \
  -subj "/CN=canopy.rpc" \
  -addext "subjectAltName=DNS:canopy.rpc,DNS:localhost,IP:127.0.0.1,IP:::1"

cat <<EOF
Generated a self-signed certificate:
  ${CERT_FILE}
  ${KEY_FILE}

This certificate is not trusted yet.
On macOS, open Keychain Access, import ${CERT_FILE}, and set it to "Always Trust".

Next steps:
  1. Add "127.0.0.1 canopy.rpc" to /etc/hosts
  2. Start Canopy RPC on http://127.0.0.1:50002
  3. Run: make run/https-rpc-proxy
  4. Use: https://canopy.rpc:8443/v1/eth
EOF
