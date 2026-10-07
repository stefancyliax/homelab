{ config, pkgs, pkgs-runner, ... }:

let
  # One-time registration token from GitHub (Settings → Actions → Runners → New self-hosted
  # runner), placed by hand. It expires after an hour, so it is not kept in the repo.
  # The file has to stay in place: the service compares against it on every start.
  tokenFile = "/var/lib/secrets/github-runner-token";
in
{
  systemd.tmpfiles.rules = [ "d /var/lib/secrets 0700 root root -" ];

  services.github-runners.homelab = {
    enable = true;
    url = "https://github.com/stefancyliax/homelab";
    inherit tokenFile;
    name = config.networking.hostName;
    # Take over a stale registration of the same name (e.g. after rebuilding the VM)
    replace = true;

    # GitHub rejects runners that fall more than ~30 days behind the latest release, and
    # stable channels stop receiving bumps once they are EOL. The package therefore comes
    # from its own nixos-unstable input, kept current by .github/workflows/update-runner.yml
    package = pkgs-runner.github-runner;
    # The nixos-25.11 module still defaults to node20 as well, which the current package dropped
    nodeRuntimes = [ "node24" ];

    # Workflows select this runner via `runs-on: [ self-hosted, nixos ]`
    extraLabels = [ "nixos" ];

    # git, nix, bash, coreutils, tar and gzip are already on the runner's PATH
    extraPackages = with pkgs; [
      curl
      gh # update-runner.yml opens its pull request with it
    ];

    serviceOverrides = {
      # Cap what a job may use (the VM has 6 GB) so a runaway step is killed inside the
      # service instead of taking the whole VM down with it
      MemoryMax = "5G";
      MemorySwapMax = "1G";
      # Only the offending process dies; the default ("stop") would end the runner too
      OOMPolicy = "continue";
    };
  };

  # Without a token file the service would fail and wipe its registration; skip it instead
  systemd.services.github-runner-homelab.unitConfig.ConditionPathExists = tokenFile;
}
