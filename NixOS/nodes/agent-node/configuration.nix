{ config, pkgs, pkgs-claude, ... }:

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

  # ── kay: the agents' shared user ────────────────────────────────────────────────────
  # Hermes, Claude Code and Antigravity all run as kay, so they share the repo checkouts
  # (~/repos), the Obsidian vault and the credentials in kay's home. stefan stays the admin
  # account; kay gets neither sudo nor docker, only what the agents need.
  # kay's primary group is its own private group `kay`, with no other members.
  users.groups.kay = { };
  users.users.kay = {
    isNormalUser = true;
    description = "Agents (Hermes, Claude Code, Antigravity)";
    group = "kay";
    home = "/home/kay";
    hashedPassword = "!";
    # The herdr desktop app connects to the node over SSH as kay, with its own key (not
    # stefan's, which would also open the admin account with its passwordless sudo)
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEv48jeL9NhGVJcl+39fzcX4yfbjX3j192n/JDPFDddB herdr → kay@agent-node"
    ];
    # User manager without a login: Hermes' gateway (a systemd user service) and cron, and
    # the agents' long-running processes
    linger = true;
  };

  # ── Hermes ──────────────────────────────────────────────────────────────────────────
  # Not in this config: Hermes is installed upstream as kay (scripts/install.sh, into
  # ~/.hermes) and manages itself, so `hermes plugins install` can add plugins with their
  # own Python dependencies and `hermes update` works. Its gateway runs as kay's systemd
  # user service (`hermes gateway install`), kept alive by linger. Its uv-managed Python
  # needs nix-ld, which modules/hermes.nix enables.

  # ── Agent tooling ───────────────────────────────────────────────────────────────────
  # The dev tools for the agents (nix-ld, node, python, ...) come from modules/hermes.nix. Claude
  # Code and Antigravity from their own nixos-unstable input (nixpkgs-claude): both ship
  # new versions far more often than the stable channel picks them up, and can't
  # self-update from the Nix store. Bump with `nix flake update nixpkgs-claude`.
  # No herdr package: the herdr desktop app brings its own backend (herdr-core).
  environment.systemPackages = [
    pkgs-claude.claude-code
    # Antigravity's terminal agent (`agy`), reached through Antigravity Remote Control
    pkgs-claude.antigravity-cli
    # Obsidian Sync without the desktop app (`ob` CLI). Only in nixos-unstable so far,
    # so it comes from nixpkgs-claude too.
    pkgs-claude.obsidian-headless
  ];

  # ── Obsidian vault ──────────────────────────────────────────────────────────────────
  # Keeps /home/kay/knowledgebase in sync with the "Knowledgebase" vault, both ways, so
  # notes the agents write go back to the other devices. Set up once as kay with
  # `ob login` and `ob sync-setup --vault Knowledgebase --path ~/knowledgebase
  # --device-name agent-node`; ob keeps the login and the vault link in kay's home.
  systemd.services.obsidian-sync = {
    description = "Obsidian Sync for kay's knowledgebase vault";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      User = "kay";
      Group = "kay";
      WorkingDirectory = "/home/kay/knowledgebase";
      ExecStart = "${pkgs-claude.obsidian-headless}/bin/ob sync --path /home/kay/knowledgebase --continuous";
      Restart = "on-failure";
      RestartSec = 30;
    };
  };

  # Garage S3 write key for the `artifacts` bucket: an AWS credentials file with a
  # [garage] profile, which is where the publish-s3 skill looks for it
  age.secrets.garage-agent-node-key = {
    file = ../../secrets/garage-agent-node-key.age;
    path = "/home/kay/.aws/credentials";
    owner = "kay";
    group = "kay";
  };

  # Agenix creates the parent directory as root; hand it to kay
  systemd.tmpfiles.rules = [
    "d /home/kay/.aws 0700 kay kay -"
  ];
}
