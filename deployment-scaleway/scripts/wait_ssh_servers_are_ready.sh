#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

SERVERS=("$(terraform output -raw server1_public_dns)")

check_ssh() {
    local server=$1
    ssh -o BatchMode=yes -o ConnectTimeout=5 "ubuntu@${server}" exit &>/dev/null
    return $?
}

while true; do
    all_ready=true
    ./scripts/update_ssh_know_hosts.sh
    for server in "${SERVERS[@]}"; do
        if ! check_ssh "$server"; then
            echo "Waiting for $server..."
            all_ready=false
        fi
    done
                
    if $all_ready; then
        echo "All servers are accessible via SSH"
        break
    fi
    sleep 5
done
