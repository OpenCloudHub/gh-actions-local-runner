<a id="readme-top"></a>

<!-- PROJECT LOGO & TITLE -->

<div align="center">
  <a href="https://github.com/opencloudhub">
  <picture>
    <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/opencloudhub/.github/main/assets/brand/assets/logos/primary-logo-light.svg">
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/opencloudhub/.github/main/assets/brand/assets/logos/primary-logo-dark.svg">
    <!-- Fallback -->
    <img alt="OpenCloudHub Logo" src="https://raw.githubusercontent.com/opencloudhub/.github/main/assets/brand/assets/logos/primary-logo-dark.svg" style="max-width:700px; max-height:175px;">
  </picture>
  </a>

<h1 align="center">Self-Hosted GitHub Actions Runner</h1>

<!-- SHORT DESCRIPTION -->

<p align="center">
    Containerized GitHub Actions runner for local development and CI/CD workflows requiring access to local Kubernetes clusters or local compute resources.<br />
    <a href="https://github.com/opencloudhub/.github"><strong>Explore the organization »</strong></a>
  </p>

<!-- BADGES -->

<p align="center">
    <a href="https://github.com/opencloudhub/.github/graphs/contributors">
      <img src="https://img.shields.io/github/contributors/opencloudhub/.github.svg?style=for-the-badge" alt="Contributors">
    </a>
    <a href="https://github.com/opencloudhub/.github/network/members">
      <img src="https://img.shields.io/github/forks/opencloudhub/.github.svg?style=for-the-badge" alt="Forks">
    </a>
    <a href="https://github.com/opencloudhub/.github/stargazers">
      <img src="https://img.shields.io/github/stars/opencloudhub/.github.svg?style=for-the-badge" alt="Stars">
    </a>
    <a href="https://github.com/opencloudhub/.github/issues">
      <img src="https://img.shields.io/github/issues/opencloudhub/.github.svg?style=for-the-badge" alt="Issues">
    </a>
    <a href="https://github.com/opencloudhub/.github/blob/main/LICENSE">
      <img src="https://img.shields.io/github/license/opencloudhub/.github.svg?style=for-the-badge" alt="License">
    </a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->

<details>
  <summary>📑 Table of Contents</summary>
  <ol>
    <li><a href="#overview">Overview</a></li>
    <li><a href="#use-cases">Use Cases</a></li>
    <li><a href="#architecture">Architecture</a></li>
    <li><a href="#prerequisites">Prerequisites</a></li>
    <li><a href="#getting-started">Getting Started</a></li>
    <li><a href="#configuration">Configuration</a></li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#maintenance">Maintenance</a></li>
    <li><a href="#troubleshooting">Troubleshooting</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>

<!-- OVERVIEW -->
<h2 id="overview">📖 Overview</h2>

This project provides a **containerized self-hosted GitHub Actions runner** designed for local development environments and CI/CD workflows that require:

- **Local Kubernetes cluster access** (e.g., Minikube, kind, k3s)
- **Local compute resources** propably higher than GitHub's standard hosted runners (2-core CPU, 7GB RAM)
- **Docker-in-Docker capabilities** for building and testing container images
- **Network isolation control** for accessing services running on the host machine
- **Custom tooling and dependencies** not available in GitHub-hosted runners

### Why Containerize the Runner?

Running the GitHub Actions runner in a Docker container provides several advantages:

- **Isolation**: Runner dependencies and workflows don't pollute your host system
- **Portability**: Same runner configuration works across different development machines
- **Resource Control**: Limit CPU, memory, and storage usage via Docker constraints
- **Security**: Restrict access to host resources through volume mounts and network policies
- **Clean State**: Each container restart provides a fresh environment
- **Development Parity**: Mirrors production self-hosted runner deployments

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- USE CASES -->
<h2 id="use-cases">🎯 Use Cases</h2>

This runner is specifically designed for workflows that require:

### 1. **Local Kubernetes Cluster Integration**
- Developing GitOps workflows with ArgoCD or Flux
- Accessing or commiting jobs to the cluster during workflows
- Testing Helm chart deployments against local clusters
- Validating Kubernetes manifests before committing
- Running integration tests that require cluster resources

### 2. **Container Image Building**
- Building multi-platform Docker images with BuildKit
- Pushing images to local or private registries
- Caching local layers for fast development build iterations

### 3. **Higher-Compute Workloads**
- Can save on cloud runner cost and enable local copute resource usage
- This can be helpful for workflos such as building larger ML container 
  images that would OOM standard GH Actions runners

### 4. **Custom Tool Requirements**
- Using tools not available in GitHub's hosted runners
- Testing with specific versions of dependencies
- Accessing proprietary or licensed software on your machine

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ARCHITECTURE -->
<h2 id="architecture">🏗️ Architecture</h2>

### Component Overview

```
┌─────────────────────────────────────────────────────┐
│                   GitHub Platform                    │
│  ┌────────────────────────────────────────────────┐ │
│  │     GitHub Actions Workflow Execution          │ │
│  └────────────┬───────────────────────────────────┘ │
│               │ Jobs assigned to 'self-hosted-local'│
└───────────────┼─────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────┐
│              Your Host Machine (Linux)               │
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │  Docker Container: gh-actions-local-runner     │ │
│  │                                                 │ │
│  │  ┌──────────────────────────────────────────┐ │ │
│  │  │   GitHub Actions Runner Process          │ │ │
│  │  │   - Polls for jobs                       │ │ │
│  │  │   - Executes workflow steps              │ │ │
│  │  │   - Reports status back to GitHub        │ │ │
│  │  └──────────────────────────────────────────┘ │ │
│  │                                                 │ │
│  │  Mounted Resources:                            │ │
│  │  - /var/run/docker.sock (Docker socket)       │ │
│  └────────────┬───────────────────────────────────┘ │
│               │                                      │
│  ┌────────────▼───────────────────────────────────┐ │
│  │         Docker Daemon (Host)                   │ │
│  │  - Builds images                               │ │
│  │  - Runs containers                             │ │
│  │  - Manages volumes                             │ │
│  └────────────┬───────────────────────────────────┘ │
│               │                                      │
│  ┌────────────▼───────────────────────────────────┐ │
│  │    Local Kubernetes Cluster                    │ │
│  │    (Minikube/kind/k3s)                         │ │
│  │  - Accessed via kubectl                        │ │
│  │  - Uses ~/.kube/config                         │ │
│  └────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

### Docker Socket Mounting

The runner uses **Docker socket mounting** rather than Docker-in-Docker (DinD):

**Advantages:**
- ✅ Shares host Docker daemon (more efficient)
- ✅ Easy to connect to other services or cluster running on host
- ✅ Better layer caching (faster builds)
- ✅ Compatible with BuildKit and multi-platform builds

**Limitation:**
> [!WARNING]  
> Workflows have access to host Docker daemon 
> and can run execute possibly dangerous code on your machine(trust required)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- PREREQUISITES -->
<h2 id="prerequisites">✅ Prerequisites</h2>

Before setting up the runner, ensure you have:

### System Requirements

- **Operating System**: Linux (Ubuntu 20.04+ recommended)
- **CPU**: 2+ cores (4+ recommended for image building)
- **RAM**: 4GB minimum (8GB+ recommended)
- **Disk Space**: 20GB+ free space (images and build cache accumulate quickly)

### Required Software

- **Docker**: Version 20.10+ ([Installation Guide](https://docs.docker.com/engine/install/))
  ```bash
  docker --version
  ```

### GitHub Configuration

1. **Personal Access Token (PAT)** with the following scopes:
   - `repo` - Full repository access
   - `admin:org` - Manage runners (for organization-level runners)
   - `workflow` - Update workflow files

   Create at: `Settings > Developer settings > Personal access tokens > Fine-grained tokens`

2. **GitHub Organization**: You must be an organization admin to add self-hosted runners

3. **Runner Registration**: Access to `Settings > Actions > Runners` in your organization

### Network Configuration

- Outbound HTTPS (443) access to:
  - `github.com` - GitHub API and authentication
  - `api.github.com` - Runner registration
  - `objects.githubusercontent.com` - Artifact downloads

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->
<h2 id="getting-started">🚀 Getting Started</h2>

### 1. Clone the Repository

```bash
git clone https://github.com/opencloudhub/gh-actions-local-runner.git
cd gh-actions-local-runner
```

### 2. Build the Container Image

Build the runner image with default settings (Ubuntu 22.04, Runner 2.329.0):

```bash
docker build --tag gh-actions-local-runner .
```

**Custom versions:**
```bash
docker build \
  --build-arg UBUNTU_VERSION=22.04 \
  --build-arg RUNNER_VERSION=2.329.0 \
  --tag gh-actions-local-runner .
```

### 3. Generate GitHub Token

1. Navigate to your GitHub organization settings
2. Go to `Settings > Actions > Runners`
3. Click `New self-hosted runner`
4. Copy the registration token from the configuration commands

**Note**: Tokens expire after 1 hour and are single-use. You'll need a new token for each runner instance.

### 4. Configure Environment Variables

Create a `.env` file with your credentials:

```bash
cp .env.example .env
```

Edit `.env` with your values:
```bash
ACCESS_TOKEN=<YOUR-GITHUB-TOKEN>
ORGANIZATION=OpenCloudHub
```

> [!CAUTION]
> Never commit your `.env` file to version control. It contains sensitive credentials.

### 5. Start the Runner Container

Source the environment file and run the container:

```bash
source .env && docker run \
  --detach \
  --network host \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --group-add $(stat -c '%g' /var/run/docker.sock) \
  --ulimit nofile=65536:65536 \
  --env ORGANIZATION \
  --env ACCESS_TOKEN \
  --name local-runner \
  gh-actions-local-runner
```

**Explanation of flags:**
- `--detach`: Run container in background
- `--network host`: Share host network (allows access to localhost services)
- `-v /var/run/docker.sock:/var/run/docker.sock`: Mount Docker socket for Docker commands
- `--group-add $(stat -c '%g' /var/run/docker.sock)`: Grant Docker socket access
- `--ulimit`: Increase size
- `--env ORGANIZATION`: Your GitHub organization name
- `--env ACCESS_TOKEN`: Registration token from GitHub
- `--name local-runner`: Container name for easy management

### 5. Verify Runner Registration

Check that the runner started successfully:

```bash
docker logs local-runner -f
```

Expected output:
```
🔧 Configuring GitHub Actions runner...
   Organization: opencloudhub
   Hostname: your-machine
✅ Runner configured successfully
🚀 Starting runner...
   Waiting for GitHub Actions jobs...
```

Verify in GitHub:
- Navigate to `Settings > Actions > Runners`
- Your runner should appear with status "Idle"

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONFIGURATION -->
<h2 id="configuration">⚙️ Configuration</h2>

### Create Runner Group

Organize runners and control repository access:

1. Go to `Settings > Actions > Runner groups`
2. Click `New runner group`
3. Name it (e.g., `local-development`)
4. Select repositories that can use this runner group
5. Click `Create group`

### Assign Runner to Group

1. Go to `Settings > Actions > Runners`
2. Click on your runner
3. In the "Runner groups" section, select your created group
4. Click `Save`

### Configure Kubernetes Access (Optional)

If your workflows need to access a local Kubernetes cluster:

#### Generate Embedded Kubeconfig

```bash
# Create kubeconfig with embedded certificates (no external file dependencies)
kubectl config view --flatten --minify > /tmp/kubeconfig-embedded.yaml

# Encode for GitHub Secrets
cat /tmp/kubeconfig-embedded.yaml | base64 -w 0

# Clean up
rm /tmp/kubeconfig-embedded.yaml
```

#### Store in GitHub Secrets

1. Copy the base64-encoded output
2. Go to your organisation or repository `Settings > Secrets and variables > Actions`
3. Click `New repository secret`
4. Name: `KUBE_CONFIG`
5. Value: Paste the base64 string
6. Click `Add secret`

#### Use in Workflow

```yaml
- name: Configure kubectl
  run: |
    mkdir -p $HOME/.kube
    echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > $HOME/.kube/config
    chmod 600 $HOME/.kube/config

- name: Verify cluster access
  run: kubectl cluster-info
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- USAGE -->
<h2 id="usage">🔧 Usage</h2>

### Reference Runner in Workflows

Target your self-hosted runner by specifying its label:

```yaml
name: Build and Test
on: [push, pull_request]

jobs:
  build:
    # Use your self-hosted runner
    runs-on: self-hosted-local
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Build Docker image
        run: docker build -t myapp:${{ github.sha }} .
      
      - name: Run tests
        run: docker run --rm myapp:${{ github.sha }} npm test
```

### Advanced Workflow Examples

#### Multi-Platform Image Build

```yaml
- name: Set up QEMU
  uses: docker/setup-qemu-action@v3

- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3

- name: Build multi-platform image
  run: |
    docker buildx build \
      --platform linux/amd64,linux/arm64 \
      --tag myapp:latest \
      --push .
```

#### Kubernetes Deployment Test

```yaml
- name: Deploy to local cluster
  run: |
    kubectl apply -f k8s/
    kubectl rollout status deployment/myapp
    kubectl get pods

- name: Run integration tests
  run: |
    kubectl port-forward service/myapp 8080:80 &
    sleep 5
    curl http://localhost:8080/health
```

### Container Management

#### View Runner Logs

```bash
# Follow logs in real-time
docker logs local-runner -f

# View last 100 lines
docker logs local-runner --tail 100
```

#### Stop the Runner

```bash
docker stop local-runner
```

The runner will gracefully unregister from GitHub.

#### Start Stopped Runner

```bash
docker start local-runner
```

**Note**: The container will need a new registration token if it was stopped for an extended period.

#### Restart Runner

```bash
docker restart local-runner
```

#### Remove Runner Container

```bash
# Stop and remove
docker rm -f local-runner

# Remove image (if rebuilding)
docker rmi gh-actions-local-runner
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MAINTENANCE -->
<h2 id="maintenance">🧹 Maintenance</h2>

### Disk Space Management

> [!WARNING]
> Docker image builds can quickly consume disk space. Build caches, intermediate layers, and unused images accumulate over time.

#### Check Disk Usage

```bash
# Check overall disk space
df -h

# Check Docker-specific usage
docker system df

# Detailed breakdown
docker system df -v
```

#### Clean Up Docker Resources
Here are some possible ways to clean up your local machine:

```bash
# Start here: Remove build cache
docker buildx prune -af

# Remove all stopped containers, unused networks, and dangling images
docker system prune -f

# Aggressive cleanup (includes unused images and build cache)
docker system prune -a -f

# Also remove volumes (⚠️ deletes persistent data)
docker system prune -a --volumes -f
```

#### Automated Cleanup in Workflows

Add cleanup steps to your workflows:

```yaml
- name: Clean up Docker
  if: always()  # Run even if previous steps fail
  run: |
    docker system prune -f --filter "until=24h"
```

#### Configure Docker Storage Limits

Edit `/etc/docker/daemon.json` on your host:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "data-root": "/mnt/docker-data"  // Optional: Move to larger partition
}
```

Restart Docker:
```bash
sudo systemctl restart docker
```

### Update Runner Version

When GitHub releases a new runner version:

1. Update the `RUNNER_VERSION` in your build command:
   ```bash
   docker build \
     --build-arg RUNNER_VERSION=2.330.0 \
     --tag gh-actions-local-runner .
   ```

2. Stop and remove the old container:
   ```bash
   docker rm -f local-runner
   ```

3. Start a new container with the updated image (see [Getting Started](#getting-started))

### Monitor Runner Health

```bash
# Check if container is running
docker ps --filter name=local-runner

# View resource usage
docker stats local-runner

# Check runner status in GitHub
# Navigate to: Settings > Actions > Runners
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- TROUBLESHOOTING -->
<h2 id="troubleshooting">🔍 Troubleshooting</h2>

### Common Issues

#### Issue: "No space left on device"

**Cause**: Docker has filled up your disk with images and build cache.

**Solution**:
```bash
# Check what's using space
docker system df

# Clean up aggressively
docker system prune -a -f

# If still full, check host disk space
df -h
```

#### Issue: Runner not appearing in GitHub

**Possible causes**:
1. **Token expired**: Registration tokens expire after 1 hour
   - Solution: Generate a new token and recreate the container

2. **Network issues**: Runner can't reach GitHub API
   - Check: `docker logs local-runner`
   - Verify: Outbound HTTPS access to `github.com`

3. **Wrong organization name**
   - Verify: `ORGANIZATION` environment variable matches exactly

#### Issue: "Permission denied" for Docker socket

**Cause**: Runner user doesn't have access to Docker socket.

**Solution**:
Ensure you're using the `--group-add` flag:
```bash
--group-add $(stat -c '%g' /var/run/docker.sock)
```

#### Issue: Workflows time out connecting to local services

**Cause**: Network isolation between container and host.

**Solution**:
Use `--network host` when starting the container, or reference services by host IP instead of `localhost`.

#### Issue: Kubectl can't find cluster

**Cause**: Kubeconfig not accessible or incorrect.

**Solutions**:
1. Verify secret is correctly base64 encoded
2. Check kubeconfig has embedded certificates (not file paths)
3. Ensure cluster is accessible from container network

### Enable Debug Logging

For more detailed logs, set debug environment variable:

```bash
docker run \
  --detach \
  --network host \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --group-add $(stat -c '%g' /var/run/docker.sock) \
  --env ORGANIZATION=<YOUR-GITHUB-ORG> \
  --env ACCESS_TOKEN=<YOUR-GITHUB-TOKEN> \
  --env RUNNER_DEBUG=1 \
  --name local-runner \
  gh-actions-local-runner
```

### Getting Help

If you encounter issues not covered here:

1. Check runner logs: `docker logs local-runner -f`
2. Review [GitHub Actions documentation](https://docs.github.com/en/actions)
3. Open an issue in this repository
4. Join our [community discussions](https://github.com/orgs/opencloudhub/discussions)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- LICENSE -->

<h2 id="license">📄 License</h2>

Distributed under the Apache 2.0 License. See [LICENSE](/LICENSE) for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->

<h2 id="contact">📬 Contact</h2>

Organization Link: [https://github.com/OpenCloudHub](https://github.com/OpenCloudHub)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

______________________________________________________________________

<div align="center">
  <h3>🌟 Follow the Journey</h3>
  <p><em>Building in public • Learning together • Sharing knowledge</em></p>

<div>
    <a href="https://opencloudhub.github.io/docs">
      <img src="https://img.shields.io/badge/Read%20the%20Docs-2596BE?style=for-the-badge&logo=read-the-docs&logoColor=white" alt="Documentation">
    </a>
    <a href="https://github.com/orgs/opencloudhub/discussions">
      <img src="https://img.shields.io/badge/Join%20Discussion-181717?style=for-the-badge&logo=github&logoColor=white" alt="Discussions">
    </a>
    <a href="https://github.com/orgs/opencloudhub/projects/4">
      <img src="https://img.shields.io/badge/View%20Roadmap-0052CC?style=for-the-badge&logo=jira&logoColor=white" alt="Roadmap">
    </a>
  </div>
</div>

<!-- MARKDOWN LINKS & IMAGES -->