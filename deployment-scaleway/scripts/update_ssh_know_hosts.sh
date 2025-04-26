#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

ssh-keygen -R $(terraform output -raw server1_public_dns) > /dev/null 2>&1 || true

ssh-keyscan -H $(terraform output -raw server1_public_dns) >> ~/.ssh/known_hosts 2> /dev/null || true
