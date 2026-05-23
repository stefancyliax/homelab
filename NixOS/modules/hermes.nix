{ config, pkgs, ... }:

{
  # Dev tools for coding agent workflows
  environment.systemPackages = with pkgs; [
    git
    gh
    neovim
    tree
    ripgrep
    fd
    jq
    nodejs      # Hermes runtime dependency
    uv
    python311
  ];
}
