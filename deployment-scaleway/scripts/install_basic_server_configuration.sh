#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

./scripts/update_ssh_know_hosts.sh
./scripts/wait_ssh_servers_are_ready.sh

SERVER1_PUBLIC_DNS=$(terraform output -raw server1_public_dns)

ssh ubuntu@${SERVER1_PUBLIC_DNS} "sudo SERVER_FQDN=\"${SERVER1_PUBLIC_DNS}\" bash -s" < _payload_install_basic_server_configuration.sh

if ssh ubuntu@${SERVER1_PUBLIC_DNS} '[ -f /var/run/reboot-required ]'; then
    echo "Reboot the server"
    ssh ubuntu@${SERVER1_PUBLIC_DNS} 'sudo reboot' || true

    while ! ssh -q -o ConnectTimeout=5 -o BatchMode=yes ubuntu@${SERVER1_PUBLIC_DNS} exit&>/dev/null; do
      echo "Wait SSH ready..."
      sleep 5
    done
    echo "SSH is ready, server is up!"
fi
