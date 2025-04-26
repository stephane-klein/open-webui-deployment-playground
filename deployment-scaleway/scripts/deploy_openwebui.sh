#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

export S3_ACCESS_KEY_ID=$(terraform output -raw sklein_openwebui_poc_data_api_access_key)
export S3_SECRET_ACCESS_KEY=$(terraform output -raw sklein_openwebui_poc_data_api_secret_key)

SERVER1_PUBLIC_DNS=$(terraform output -raw server1_public_dns)
export VIRTUAL_HOST=${SERVER1_PUBLIC_DNS}

gomplate -f _payload_deploy_openwebui.sh | ssh ubuntu@${SERVER1_PUBLIC_DNS} 'sudo bash -s'

cat <<EOF

Go to https://$(terraform output -raw server1_public_dns)
  - email: ${OPENWEBUI_ADMIN_EMAIL}
  - password: ${OPENWEBUI_ADMIN_PASSWORD}
EOF
