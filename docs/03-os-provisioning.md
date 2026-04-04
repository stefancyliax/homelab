# 03 - OS Provisioning (NixOS & Colmena)

All Linux-based nodes in this lab (aside from HAOS and the NAS) are provisioned using NixOS to ensure reproducibility and declarative configurations.

## 🛠️ Colmena Deployment

Configurations are managed centrally via a Flake and applied using `colmena`. 

### Structure
* `flake.nix` & `hive.nix`: Define the network and assign configurations to hostnames.
* `common.nix`: Shared base configuration across all NixOS machines (tailscale, guest agent, base packages).
* `nodes/`: Directory containing machine-specific configurations (e.g., configurations specific to the `gpu-worker` vs the `services-vm`).

### 🔒 Secrets Management

We utilize **Agenix** natively within the `NixOS` environments for encrypting and strictly handling secrets. Public SSH host-keys for the physical deployment machines (as well as explicit user keys) are mapped exclusively in the root `secrets.nix` file.

## 📝 VM Templating & Cloning

When utilizing a baseline NixOS VM pattern to clone instances across your Proxmox pool, you must explicitly ensure that hardware-tied entity states are wiped. If they aren't, configurations heavily reliant on unique host identification (like Tailscale IP allocation and Agenix decryption) will significantly conflict across your cluster.

Right before converting your configured base VM into a Proxmox template, execute:
```bash
sudo rm /etc/machine-id
sudo rm /etc/ssh/ssh_host_*
sudo shutdown now
```
> [!NOTE] 
> NixOS is designed to automatically generate completely clean, unique SSH host keys and a fresh `machine-id` strictly upon the first system boot of the cloned VM.

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
