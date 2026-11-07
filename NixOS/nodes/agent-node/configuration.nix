{ config, pkgs, pkgs-claude, herdr, ... }:

{
  imports = [
    ../../common.nix
    ./hardware-configuration.nix
  ];

  # Bootloader (OVMF/UEFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "agent-node";

  # No doc outputs in the system profile. Headless VM, nobody reads them here, and the
  # python311 from modules/hermes.nix pulls python3.11-doc, which isn't in the binary cache
  # and whose Sphinx build fails on 26.05 (docutils 0.22).
  documentation.doc.enable = false;

  # Hermes Agent as a service (module from the hermes-agent flake input). It runs as its own
  # `hermes` user with state in /var/lib/hermes; `hermes` on the PATH shares that state, and
  # stefan is in the hermes group so the CLI can write config.yaml. Settings here are merged
  # into config.yaml on each activation; runtime edits to other keys survive.
  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    settings.model = {
      # llama-swap on the gpu-worker (OpenAI-compatible, no API key)
      provider = "custom";
      base_url = "http://100.90.253.20:8080/v1";
      default = "qwen3.6-35b";
    };
    # Secrets (messaging gateway tokens, API keys) go into an Agenix env file:
    # environmentFiles = [ config.age.secrets.hermes-env.path ];
  };
  users.users.stefan.extraGroups = [ "hermes" ];

  # llama-swap on the gpu-worker listens on its Tailscale address only.
  # Join once after deploy with `sudo tailscale up`.
  services.tailscale.enable = true;

  # Agent tooling. The Hermes dev tools (nix-ld, node, python, ...) come from
  # modules/hermes.nix. Claude Code and Antigravity from their own nixos-unstable input
  # (nixpkgs-claude): both ship new versions far more often than the stable channel picks
  # them up, and can't self-update from the Nix store. Bump with
  # `nix flake update nixpkgs-claude`.
  environment.systemPackages = [
    pkgs-claude.claude-code
    # Antigravity's terminal agent (`agy`). The node is headless, so not the IDE; the IDE
    # on the laptop reaches the node over remote SSH.
    pkgs-claude.antigravity-cli
    herdr # from the herdr flake input, see flake.nix
    # Obsidian Sync without the desktop app (`ob` CLI). Only in nixos-unstable so far,
    # so it comes from nixpkgs-claude too. Being tested; no sync service declared yet.
    pkgs-claude.obsidian-headless
  ];

  # Garage S3 write key for the `artifacts` bucket: an AWS credentials file with a
  # [garage] profile, which is where the publish-s3 skill looks for it
  age.secrets.garage-agent-node-key = {
    file = ../../secrets/garage-agent-node-key.age;
    path = "/home/stefan/.aws/credentials";
    owner = "stefan";
    group = "users";
  };

  # Agenix creates the parent directory as root; hand it to stefan
  systemd.tmpfiles.rules = [
    "d /home/stefan/.aws 0700 stefan users -"
  ];
}
