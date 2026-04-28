{ config, pkgs, ... }:

{
  services.comin = {
    enable = true;
    repositorySubdir = "NixOS";
    exporter.openFirewall = true;
    remotes = [{
      name = "origin";
      url = "https://github.com/stefancyliax/homelab.git";
      branches.main.name = "main";
      auth.access_token_path = config.age.secrets."github-pat".path;
    }];
  };

  # ntfy notifications for Comin deployments
  systemd.services."ntfy-comin-success" = {
    description = "Notify ntfy on successful Comin deployment";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        ${pkgs.curl}/bin/curl -s \
          -H "Title: ✅ Deployment succeeded" \
          -H "Tags: white_check_mark" \
          -d "Node: ${config.networking.hostName}" \
          http://10.1.23.184:2586/homelab-deployments
      '';
    };
  };

  systemd.services."ntfy-comin-failure" = {
    description = "Notify ntfy on failed Comin deployment";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        ${pkgs.curl}/bin/curl -s \
          -H "Title: ❌ Deployment failed" \
          -H "Tags: x" \
          -H "Priority: high" \
          -d "Node: ${config.networking.hostName}" \
          http://10.1.23.184:2586/homelab-deployments
      '';
    };
  };

  systemd.services.comin.unitConfig = {
    OnSuccess = [ "ntfy-comin-success.service" ];
    OnFailure = [ "ntfy-comin-failure.service" ];
  };

  # Decrypt the GitHub PAT using agenix
  age.secrets."github-pat" = {
    file = ../secrets/github-pat.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };
}
