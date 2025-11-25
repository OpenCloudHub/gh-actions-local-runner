#!/bin/bash
# =============================================================================
# start.sh - GitHub Actions Self-Hosted Runner Entrypoint
# =============================================================================
#
# Purpose:
#   Configures and starts a self-hosted GitHub Actions runner within a Docker
#   container. This runner registers with GitHub and executes workflows on the
#   host machine, enabling access to local resources like Kubernetes clusters
#   and higher compute resources than GitHub's standard runners.
#
# Why use a containerized runner?
#   - Isolation: Runner dependencies don't pollute the host system
#   - Portability: Easy to deploy across different environments
#   - Consistency: Same runner configuration everywhere
#   - Security: Limited access to host resources (only Docker socket)
#   - Clean state: Container restart resets runner environment
#
# Required Environment Variables:
#   ORGANIZATION - GitHub organization name (e.g., 'opencloudhub')
#   ACCESS_TOKEN - GitHub PAT with 'repo' and 'admin:org' scopes
#
# Runtime Behavior:
#   1. Registers runner with GitHub using provided credentials
#   2. Assigns custom label 'self-hosted-local' for workflow targeting
#   3. Starts runner process and waits for jobs
#   4. Gracefully unregisters on container stop (SIGINT/SIGTERM)
#
# Signal Handling:
#   SIGINT (Ctrl+C)  - Triggers cleanup and exits with code 130
#   SIGTERM (docker stop) - Triggers cleanup and exits with code 143
#
# =============================================================================

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

ORGANIZATION=${ORGANIZATION:?ERROR: ORGANIZATION environment variable is required}
ACCESS_TOKEN=${ACCESS_TOKEN:?ERROR: ACCESS_TOKEN environment variable is required}

# =============================================================================
# Functions
# =============================================================================

# Cleanup function - removes runner registration from GitHub
# Called on script exit (normal or signal-triggered)
cleanup() {
    echo "🧹 Removing runner from GitHub..."
    ./config.sh remove --unattended --token "${ACCESS_TOKEN}" || true
    echo "✅ Runner removed successfully"
}

# =============================================================================
# Main Execution
# =============================================================================

# Change to runner installation directory
cd /home/runner/actions-runner

echo "🔧 Configuring GitHub Actions runner..."
echo "   Organization: ${ORGANIZATION}"
echo "   Hostname: $(hostname)"

# Register runner with GitHub
# --url: GitHub organization URL
# --token: Personal Access Token for authentication
# --labels: Custom labels for targeting this runner in workflows
# --name: Unique runner name (hostname-based to avoid conflicts)
# --unattended: Non-interactive mode for automation
./config.sh \
    --url "https://github.com/${ORGANIZATION}" \
    --token "${ACCESS_TOKEN}" \
    --labels self-hosted-local \
    --name "local-runner-$(hostname)" \
    --unattended

echo "✅ Runner configured successfully"

# Set up signal handlers for graceful shutdown
trap 'cleanup; exit 130' INT   # Handle Ctrl+C
trap 'cleanup; exit 143' TERM  # Handle docker stop

echo "🚀 Starting runner..."
echo "   Waiting for GitHub Actions jobs..."
echo "   Press Ctrl+C to stop"

# Start the runner in background and wait for it
# Using wait allows signal handlers to work properly
./run.sh & wait $!