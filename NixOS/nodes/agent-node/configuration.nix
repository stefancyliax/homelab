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
  # kay's primary group is its own private group `kay`, with no other members. Hermes needs
  # that: the module sets HERMES_HOME to 2770, and the CLI only accepts a group-writable
  # home when the group is the owner's private one.
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
    # User manager without a login: Hermes' cron and the agents' long-running processes
    linger = true;
  };

  # ── Hermes ──────────────────────────────────────────────────────────────────────────
  # Service from the hermes-agent flake input. Runs as kay with its state in kay's home:
  # HOME is /home/kay and HERMES_HOME /home/kay/.hermes, the CLI's default, so `hermes`
  # as kay talks to the running gateway. The module also creates /home/kay/home (unused
  # here) and sets /home/kay to 2770 kay:kay. Settings here are merged into config.yaml on
  # each activation; runtime edits to other keys survive.
  services.hermes-agent = {
    enable = true;
    user = "kay";
    group = "kay";
    createUser = false;
    stateDir = "/home/kay";
    workingDirectory = "/home/kay/repos";
    addToSystemPackages = true;
    # Nous Portal; log in once as kay with `hermes auth add nous` (stored in auth.json).
    # Managed mode: the CLI can't save config (`hermes model`, `hermes config set`), so the
    # model is set here. `hermes model` still lists the models to pick from. Without a model,
    # every new session fails with storage_unavailable.
    settings.model = {
      provider = "nous";
      default = "z-ai/glm-5.3-flash";
    };
    # Secrets (Discord/Telegram tokens for the messaging gateway) go into an Agenix env file:
    # environmentFiles = [ config.age.secrets.hermes-env.path ];
  };

  # ── Agent tooling ───────────────────────────────────────────────────────────────────
  # The Hermes dev tools (nix-ld, node, python, ...) come from modules/hermes.nix. Claude
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
