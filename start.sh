#!/bin/bash

# Required environment variables
ORGANIZATION=$ORGANIZATION
ACCESS_TOKEN=$ACCESS_TOKEN

# Get registration token from GitHub API
# REG_TOKEN=$(curl -sX POST -H "Authorization: token ${ACCESS_TOKEN}" \
#     https://api.github.com/orgs/${ORGANIZATION}/actions/runners/registration-token | \
#     jq .token --raw-output)

# Change to the correct directory
cd /home/runner/actions-runner

# Configure the runner
./config.sh --url https://github.com/${ORGANIZATION} \
    --token ${ACCESS_TOKEN} \
    --labels self-hosted-local \
    --name "local-runner-$(hostname)" \
    --unattended

# Cleanup function
cleanup() {
    echo "Removing runner..."
    ./config.sh remove --unattended --token ${ACCESS_TOKEN}
}

# Set up signal handlers
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# Start the runner
./run.sh & wait $!