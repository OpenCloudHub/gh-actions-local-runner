# syntax=docker/dockerfile:1
ARG UBUNTU_VERSION=22.04
ARG RUNNER_VERSION=2.327.1

FROM ubuntu:${UBUNTU_VERSION}

# Re-declare ARG after FROM to make it available in this stage
ARG RUNNER_VERSION
ENV RUNNER_VERSION=${RUNNER_VERSION}

# Add system dependencies
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
    rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m runner && \
    mkdir -p /home/runner/actions-runner && \
    chown -R runner:runner /home/runner

# Switch to runner user
USER runner
WORKDIR /home/runner/actions-runner

# Download and extract GitHub Actions runner
RUN curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    rm ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Copy entrypoint
COPY --chown=runner:runner start.sh /home/runner/actions-runner/start.sh
RUN chmod +x start.sh

# Entrypoint
ENTRYPOINT ["./start.sh"]