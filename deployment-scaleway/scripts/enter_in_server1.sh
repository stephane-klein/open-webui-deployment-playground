#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

ssh ubuntu@$(terraform output -raw server1_public_dns)
