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
    postDeploymentCommand = toString (pkgs.writeShellScript "comin-notify" ''
      if [ -z "$COMIN_ERROR_MSG" ]; then
        ${pkgs.curl}/bin/curl -s \
          -H "Title: Deployment succeeded" \
          -H "Tags: white_check_mark" \
          -d "Node: $COMIN_HOSTNAME
      Commit: $COMIN_GIT_MSG ($COMIN_GIT_SHA)" \
          http://10.1.23.184:2586/homelab-deployments
      else
        ${pkgs.curl}/bin/curl -s \
          -H "Title: ❌ Deployment failed" \
          -H "Tags: x" \
          -H "Priority: high" \
          -d "Node: $COMIN_HOSTNAME
      Commit: $COMIN_GIT_MSG ($COMIN_GIT_SHA)
      Error: $COMIN_ERROR_MSG" \
          http://10.1.23.184:2586/homelab-deployments
      fi
    '');
  };

  # Decrypt the GitHub PAT using agenix
  age.secrets."github-pat" = {
    file = ../secrets/github-pat.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };
}
