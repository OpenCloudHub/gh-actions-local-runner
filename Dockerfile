# syntax=docker/dockerfile:1
# =============================================================================
# Dockerfile - Self-Hosted GitHub Actions Runner
# =============================================================================
#
# Purpose:
#   Creates a containerized GitHub Actions runner with Docker-in-Docker support
#   for executing CI/CD workflows that require Docker commands and local resource
#   access (e.g., local Kubernetes clusters).
#
# Key Features:
#   - Ubuntu-based for compatibility with most GitHub Actions
#   - Docker CLI included for building/pushing images within workflows
#   - Non-root user for security
#   - GitHub Actions runner pre-installed and configured
#
# Architecture:
#   This container uses Docker socket mounting to execute Docker commands on
#   the host. This approach (vs. Docker-in-Docker) is:
#   - More efficient (shares host Docker daemon)
#   - Compatible with BuildKit and other advanced Docker features
#
# Build Arguments:
#   UBUNTU_VERSION - Base Ubuntu version (default: 22.04 LTS)
#   RUNNER_VERSION - GitHub Actions runner version (default: 2.329.0)
#
# Build Command:
#   docker build --tag gh-actions-local-runner .
#
# Runtime Requirements:
#   - Docker socket must be mounted: -v /var/run/docker.sock:/var/run/docker.sock
#   - User must have docker group access: --group-add $(stat -c '%g' /var/run/docker.sock)
#   - Environment variables: ORGANIZATION and ACCESS_TOKEN
#
# =============================================================================

# =============================================================================
# Build Arguments
# =============================================================================

ARG UBUNTU_VERSION=22.04
ARG RUNNER_VERSION=2.329.0

# =============================================================================
# Base Image
# =============================================================================

FROM ubuntu:${UBUNTU_VERSION}

# Pass build args to environment for runtime access
ARG RUNNER_VERSION
ENV RUNNER_VERSION=${RUNNER_VERSION}

# =============================================================================
# System Dependencies
# =============================================================================

# Install system packages and Docker CLI
# Packages installed:
#   - curl, ca-certificates: For downloading runner and Docker installation
#   - jq: JSON processing for API interactions
#   - git: Required by GitHub Actions for repository checkouts
#   - tar, zip, unzip: Archive handling for actions
#   - libssl-dev, libffi-dev: SSL/TLS support for secure connections
#   - software-properties-common: For managing package repositories
#   - sudo: Required by some GitHub Actions
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        jq \
        git \
        tar \
        zip \
        unzip \
        libssl-dev \
        libffi-dev \
        software-properties-common \
        sudo && \
    # Install Docker CLI using official installation script
    # This provides the 'docker' command for use in workflows
    curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh get-docker.sh && \
    rm get-docker.sh && \
    # Clean up apt cache to reduce image size
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# User Configuration
# =============================================================================

# Create non-root user for running the GitHub Actions runner
# Security best practice: avoid running as root when possible
# Adding to docker group allows executing docker commands via mounted socket
RUN useradd -m runner && \
    mkdir -p /home/runner/actions-runner && \
    usermod -aG docker runner && \
    chown -R runner:runner /home/runner

# Switch to non-root user for remainder of build and runtime
USER runner
WORKDIR /home/runner/actions-runner

# =============================================================================
# GitHub Actions Runner Installation
# =============================================================================

# Download and extract the GitHub Actions runner binary
# Version is controlled by RUNNER_VERSION build argument
RUN curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    rm ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# =============================================================================
# Entrypoint Setup
# =============================================================================

# Copy and configure startup script
# This script handles runner registration and lifecycle management
COPY --chown=runner:runner start.sh /home/runner/actions-runner/start.sh
RUN chmod +x start.sh

# Set entrypoint to our custom startup script
ENTRYPOINT ["./start.sh"]