#!/usr/bin/env bash
set -e

# ── DinD: Start internal Docker daemon ──
sudo dockerd > /var/log/dockerd.log 2>&1 &

echo "Waiting for Docker daemon..."
timeout 30 sh -c 'until docker info > /dev/null 2>&1; do sleep 1; done'
echo "Docker daemon is ready."

# ── OAuth: Copy credentials on first run (read-only mount -> bind mount) ──
for dir in .claude; do
    host_dir="/tmp/${dir}-host"
    target_dir="${HOME}/${dir}"
    if [[ -d "${host_dir}" ]] && [[ -z "$(ls -A "${target_dir}" 2>/dev/null)" ]]; then
        cp -a "${host_dir}/." "${target_dir}/"
        echo "Initialized ${dir} credentials from host."
    fi
done

# ── API Key: Decrypt .env.gpg if present ──
ENV_ENC="${HOME}/work/.env.gpg"
if [[ -f "${ENV_ENC}" ]]; then
    echo "Encrypted API keys detected. Enter passphrase to decrypt:"
    decrypted=$(gpg --quiet --decrypt --batch --passphrase-fd 0 "${ENV_ENC}" < /dev/tty)
    while IFS='=' read -r key value; do
        [[ -z "${key}" || "${key}" =~ ^# ]] && continue
        export "${key}=${value}"
    done <<< "${decrypted}"
    echo "API keys loaded."
fi

exec "$@"
