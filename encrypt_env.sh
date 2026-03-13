#!/bin/bash
set -euo pipefail

# Encrypt .env to .env.gpg (GPG symmetric encryption)
# Usage: ./encrypt_env.sh

ENV_FILE=".env"
ENC_FILE=".env.gpg"

if [[ ! -f "${ENV_FILE}" ]]; then
    echo "Error: ${ENV_FILE} not found."
    echo "Please create .env first with the following format:"
    echo "  ANTHROPIC_API_KEY=sk-ant-xxxxx"
    exit 1
fi

gpg --symmetric --cipher-algo AES256 --batch --yes --output "${ENC_FILE}" "${ENV_FILE}"
echo "Encrypted to ${ENC_FILE}"
echo "You can now remove the plaintext file: rm ${ENV_FILE}"
