{ config, pkgs, ... }:

{
  programs.nix-ld.enable = true;

  # Set default system-wide editor
  environment.variables.EDITOR = "vim";

  # Dev tools for coding agent workflows
  environment.systemPackages = with pkgs; [
    git
    gh
    neovim
    vim
    tree
    ripgrep
    fd
    jq
    nodejs      # Hermes runtime dependency
    uv
    python311
  ];
}
