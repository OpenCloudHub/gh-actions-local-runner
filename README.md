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
    <li><a href="#about">About</a></li>
    <li><a href="#features">Features</a></li>
    <li><a href="#architecture">Architecture</a></li>
    <li><a href="#getting-started">Getting Started</a></li>
    <li><a href="#configuration">Configuration</a></li>
    <li><a href="#project-structure">Project Structure</a></li>
    <li><a href="#troubleshooting">Troubleshooting</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>

<!-- ABOUT -->
<h2 id="about">🎯 About</h2>

This project provides a **containerized self-hosted GitHub Actions runner** designed for local development environments. It enables CI/CD workflows to access local resources such as Kubernetes clusters running on the host machine, while keeping the runner isolated in a Docker container.

### Why This Runner?

Standard GitHub-hosted runners operate in GitHub's cloud infrastructure and cannot access resources on your local machine. This runner bridges that gap by:

- Running on your local machine inside a Docker container
- Connecting to local Kubernetes clusters (Minikube, kind, k3s)
- Using host Docker daemon for building and pushing container images
- Providing higher compute resources than GitHub's standard runners (2-core CPU, 7GB RAM)

### 📚 Thesis Context

> This runner is developed as part of a Master's thesis project exploring cloud-native MLOps infrastructure. It serves as the **local development bridge** between GitHub Actions workflows and a local Minikube cluster.

**Development Use Case:**
- Test GitHub Actions workflows against a local Kubernetes cluster before deploying to production
- Build and push container images using the host's Docker daemon
- Validate GitOps deployments with ArgoCD locally

**Production Considerations:**
In a production environment, you would typically not use a local self-hosted runner. Instead, consider:
- **GitHub-hosted runners** for standard CI tasks
- **Self-hosted runners in Kubernetes** using [actions-runner-controller](https://github.com/actions/actions-runner-controller) for cluster-integrated workflows
- **Cloud-based self-hosted runners** (AWS, GCP, Azure) for custom compute requirements

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- FEATURES -->
<h2 id="features">✨ Features</h2>

- **🐳 Containerized Runner** - Isolated execution environment that doesn't pollute your host system
- **🔌 Docker Socket Mounting** - Access host Docker daemon for building images without Docker-in-Docker overhead
- **☸️ Kubernetes Integration** - Connect to local clusters (Minikube, kind, k3s) via kubeconfig
- **🏷️ Custom Labels** - Target specific workflows with `self-hosted-local` label
- **🔄 Graceful Lifecycle** - Automatic registration/deregistration with GitHub on start/stop
- **🛡️ Non-Root Execution** - Runs as unprivileged user for security
- **📦 Minimal Dependencies** - Ubuntu-based with only essential tools pre-installed

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
> Workflows have access to host Docker daemon and can execute potentially dangerous code on your machine (trust required).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->
<h2 id="getting-started">🚀 Getting Started</h2>

### Prerequisites

Before setting up the runner, ensure you have:

- **Operating System**: Linux (Ubuntu 20.04+ recommended)
- **Docker**: Version 20.10+ ([Installation Guide](https://docs.docker.com/engine/install/))
- **GitHub Organization**: Admin access to add self-hosted runners
- **Disk Space**: 20GB+ free space (images and build cache accumulate quickly)

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

> [!NOTE]
> Tokens may expire. You'll need a new token for each runner instance.

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

First, remove any existing container:

```bash
docker rm -f local-runner 2>/dev/null || true
```

Then start the runner using the environment file:

```bash
docker run \
  --detach \
  --network host \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --group-add $(stat -c '%g' /var/run/docker.sock) \
  --ulimit nofile=65536:65536 \
  --env-file .env \
  --name local-runner \
  gh-actions-local-runner
```

**Explanation of flags:**
- `--detach`: Run container in background
- `--network host`: Share host network (allows access to localhost services)
- `-v /var/run/docker.sock:/var/run/docker.sock`: Mount Docker socket for Docker commands
- `--group-add $(stat -c '%g' /var/run/docker.sock)`: Grant Docker socket access
- `--ulimit`: Increase file descriptor limit
- `--env-file .env`: Load environment variables from file
- `--name local-runner`: Container name for easy management

### 6. Verify Runner Registration

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

<!-- PROJECT STRUCTURE -->
<h2 id="project-structure">📁 Project Structure</h2>

```
gh-actions-local-runner/
├── .github/
│   └── workflows/
│       └── test-connection.yaml  # Example workflow to test cluster connectivity
├── Dockerfile                    # Container image definition
├── start.sh                      # Runner entrypoint script (registration/lifecycle)
├── .env.example                  # Template for environment variables
├── .gitignore                    # Git ignore rules (includes .env)
├── LICENSE                       # Apache 2.0 license
└── README.md                     # This documentation
```

### Key Files

| File           | Purpose                                                                      |
| -------------- | ---------------------------------------------------------------------------- |
| `Dockerfile`   | Builds Ubuntu-based image with GitHub Actions runner and Docker CLI          |
| `start.sh`     | Handles runner registration, signal handling, and graceful shutdown          |
| `.env.example` | Template for required environment variables (`ACCESS_TOKEN`, `ORGANIZATION`) |

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

### Runner Management

```bash
# View logs
docker logs local-runner -f

# Stop runner (gracefully unregisters from GitHub)
docker stop local-runner

# Restart runner
docker restart local-runner

# Remove and recreate
docker rm -f local-runner
```

### Disk Space Cleanup

> [!WARNING]
> Docker image builds can quickly consume disk space.

```bash
# Check Docker disk usage
docker system df

# Clean build cache
docker buildx prune -af

# Aggressive cleanup (removes unused images)
docker system prune -a -f
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- TROUBLESHOOTING -->
<h2 id="troubleshooting">🔍 Troubleshooting</h2>

### Common Issues

| Issue                                 | Cause                    | Solution                                               |
| ------------------------------------- | ------------------------ | ------------------------------------------------------ |
| "No space left on device"             | Docker disk full         | Run `docker system prune -a -f`                        |
| Runner not appearing in GitHub        | Token expired (1h limit) | Generate new token, recreate container                 |
| "Permission denied" for Docker socket | Missing group access     | Add `--group-add $(stat -c '%g' /var/run/docker.sock)` |
| Kubectl can't find cluster            | Bad kubeconfig           | Verify base64 encoding and embedded certificates       |

### Enable Debug Logging

```bash
docker run --detach --network host \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --group-add $(stat -c '%g' /var/run/docker.sock) \
  --env-file .env \
  --env RUNNER_DEBUG=1 \
  --name local-runner \
  gh-actions-local-runner
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTRIBUTING -->
<h2 id="contributing">👥 Contributing</h2>

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

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