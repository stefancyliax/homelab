# 03 - OS Provisioning (NixOS & Colmena)

All Linux-based nodes in this lab (aside from HAOS and the NAS) are provisioned using NixOS to ensure reproducibility and declarative configurations.

## 🛠️ Colmena Deployment

Configurations are managed centrally via a Flake and applied using `colmena`. 

### Structure
* `flake.nix` & `hive.nix`: Define the network and assign configurations to hostnames.
* `common.nix`: Shared base configuration across all NixOS machines (tailscale, guest agent, base packages).
* `nodes/`: Directory containing machine-specific configurations (e.g., configurations specific to the `gpu-worker` vs the `services-vm`).

### 🔒 Secrets Management

> [!WARNING]
> **TODO:** Implement proper secrets management. Currently, the public SSH key is directly embedded in `configuration.nix`. 

**Planned Approach:**
Research and integrate `sops-nix` or `agenix` to securely encrypt secrets (like database passwords, Tailscale auth keys, API tokens) directly within this Git repository. The NixOS runner/nodes will decrypt these at deployment time using their local SSH host keys or age keys.

## 🚀 Deployment Process

The deployment workflow acts on a push-model mechanism either from a CI runner or an administrator's machine.

### GitHub Actions Runner
A dedicated NixOS VM acts as a GitHub Actions runner. When updates are pushed to the `main` branch, the runner triggers the `colmena apply` process, deploying the declarative changes over SSH to the target machines.

### Manual Application
To push configuration updates to all targeted nodes from an authorized local machine (useful during bootstrapping or debugging):
```bash
export COLMENA_SSH_OPTS="-o StrictHostKeyChecking=no"
colmena apply --flake ./NixOS
```

Apply to a specific node:
```bash
colmena apply --flake ./NixOS --on gpu-worker
```

### Local Provisioning
If you are logged directly into a NixOS node and want to apply the configuration locally (e.g., during bootstrapping):
```bash
cd NixOS/
sudo colmena apply-local --flake . --on <node_name>
```

> [!NOTE]
> For the first-time provisioning, ensure your user is added to `trusted-users` in `common.nix` and has `NOPASSWD` sudo rights.
