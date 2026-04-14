# Deployment

This document covers how the homelab is deployed and managed — from NixOS system configurations to application containers. Everything follows a GitOps model where this repository is the single source of truth.

## NixOS Provisioning

All Linux-based nodes (aside from HAOS and the NAS) are provisioned using NixOS for reproducible, declarative configurations.

### Flake Structure

The NixOS configurations live in the `NixOS/` directory and are managed as a Nix Flake:

```
NixOS/
├── flake.nix       # Flake entry point, defines inputs (nixpkgs, colmena, agenix)
├── flake.lock      # Pinned dependency versions
├── common.nix      # Shared base config (Tailscale, QEMU guest agent, base packages)
├── nodes/          # Per-node configurations
│   ├── infra-node/
│   ├── services-node/
│   └── gpu-worker/
├── modules/        # Reusable NixOS modules
│   ├── dockhand.nix
│   └── hawser.nix
├── secrets/        # Agenix-encrypted secret files (.age)
└── secrets.nix     # Maps SSH public keys to secret files for decryption
```

### Colmena (Push Model)

[Colmena](https://github.com/zhaofengli/colmena) is used to deploy NixOS configurations to always-online nodes. It evaluates the flake, builds the system closures, and pushes them to the target machines over SSH.

The `flake.nix` defines a `colmenaHive` mapping each node to its configuration and deployment target (IP address).

### Comin (Pull Model)

For nodes that are frequently offline (like the `gpu-worker`), a push model would time out and fail the CI pipeline. These nodes instead run the [Comin](https://github.com/nlewo/comin) service, which:

1. Authenticates to Git when the node powers on.
2. Fetches the latest flake updates automatically.
3. Applies them without manual intervention.

This cleanly decouples intermittent nodes from the rigid timeouts of centralized push deployments.

#### Why Migrate All Nodes to Comin?
We are actively transitioning the entire cluster away from Colmena towards Comin for the following architectural benefits:
- **Better Version Handling:** Native Comin deployments accurately stamp the OS with the Git Flake commit. Colmena-deployed hosts often generically show "25.11pre-git" without workarounds.
- **Improved Security (No Centralized Push):** We no longer need a central GitHub Actions runner storing SSH private keys with root access to every single node.
- **Resilience:** Comin natively handles intermittent nodes (like the GPU worker) entering and leaving the network without breaking CI pipelines.
- **Architectural Alignment:** Using a single, unified deployment model across all nodes reduces operational overhead.
- **Native Syntax:** Pull-based deployment allows us to completely omit Colmena-specific syntax (`colmenaHive` mapping and `deployment` attributes), returning fully to standard `nixosConfigurations`.

### Secrets Management (Agenix)

[Agenix](https://github.com/ryantm/agenix) encrypts secrets at rest in the repository using SSH public keys. At deployment time, NixOS decrypts them using the host's private SSH key.

- **`secrets.nix`**: Maps which SSH public keys (host keys + user keys) can decrypt which secret files.
- **`secrets/*.age`**: The encrypted secret payloads (e.g., `hawser-token.age`).
- Secrets are referenced in NixOS configs via `age.secrets.<name>.file` and made available as files on the target system.

### VM Templating & Cloning

When cloning a baseline NixOS VM into a Proxmox template, hardware-tied state must be wiped to avoid conflicts (Tailscale IP allocation, Agenix decryption, etc.):

```bash
# Run on the base VM right before converting to a template
sudo rm /etc/machine-id
sudo rm /etc/ssh/ssh_host_*
sudo shutdown now
```

> [!NOTE]
> NixOS automatically generates fresh SSH host keys and a new `machine-id` on the first boot of a cloned VM.

## Application Deployment

The application layer uses a GitOps pull-model via Docker Compose, orchestrated by Dockhand and Hawser.

### Workflow

1. Docker Compose files are maintained in this repository under `infra-stack/` and `services-stack/`.
2. When code is pushed to `main`, a GitHub Actions workflow fires on the self-hosted runner.
3. The runner triggers Dockhand's internal REST webhooks.
4. Dockhand pulls the updated configurations from Git and routes the deployment to the target nodes via the Hawser agent API.

### Dockhand & Hawser

- **[Dockhand](https://github.com/nicotsx/dockhand):** Runs natively on the Infrastructure Node via NixOS OCI containers (not Docker Compose). It binds to the local Docker socket and orchestrates deployments across the cluster.
- **[Hawser](https://github.com/nicotsx/hawser):** A lightweight agent that runs on remote nodes (like the Services Node). It mounts the local Docker socket and exposes a REST interface secured by an Agenix-encrypted token. Dockhand communicates with Hawser to deploy containers on remote nodes without exposing the raw Docker API.

### Infrastructure vs. Services

The application stacks are split across VMs to prevent monolithic failures:

- **`infra-stack/`** → Infrastructure Node — foundational services (ZeroByte, Homepage, monitoring).
- **`services-stack/`** → Services Node — user-facing applications (Paperless, NocoDB, etc.).

See [architecture.md](architecture.md) for the full service-to-node mapping.

### Adding a New Service

1. Create or append to the `docker-compose.yml` in the relevant stack directory (`infra-stack/` or `services-stack/`).
2. Commit and push to the `main` branch.
3. The path-bound GitHub Actions workflow detects the change.
4. The runner fires the appropriate Dockhand webhook, deploying the containers automatically via Hawser.

## CI/CD Pipeline

A dedicated NixOS VM runs a self-hosted GitHub Actions runner inside the local network:

- **`nixos-apply.yml`**: Triggers `colmena apply` when NixOS configs change on `main`.
- **`dockhand-infra.yml`**: Triggers the Dockhand webhook for `infra-stack` changes.
- **`dockhand-services.yml`**: Triggers the Dockhand webhook for `services-stack` changes.

## Deployment Commands

### Remote Deployment (from Mac or Runner)

Push configurations to one or all nodes:

```bash
# Apply to all nodes
export COLMENA_SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
colmena apply --flake ./NixOS

# Apply to a specific node
colmena apply --flake ./NixOS --on gpu-worker
```

### Local Provisioning (directly on a Node)

If logged into a NixOS node, apply the configuration locally (e.g., during bootstrapping):

```bash
cd NixOS/
sudo colmena apply-local --flake . --on <node_name>
```

> [!NOTE]
> For first-time provisioning, ensure your user is added to `trusted-users` in `common.nix` and has `NOPASSWD` sudo rights.

### Checking Deployed Version

To check the exact Git commit SHA that a NixOS node is currently running, log into the node and run:

```bash
nixos-version --configuration-revision
```

This returns the `self.rev` (or `self.dirtyRev`) set during the build, allowing you to instantly verify if the running configuration matches the remote repository.

## Deployment Monitoring

Monitoring the health and status of deployments is planned using Prometheus and Grafana.

- **Comin metrics:** Comin nodes export GitOps status metrics on port 4242, which Prometheus will scrape to track pull-based deployment success and revision history.
- **Deployment dashboards:** Grafana will visualize deployment frequency, success/failure rates, and current running revisions across the cluster.

See [monitoring.md](monitoring.md) for the full monitoring stack design.
