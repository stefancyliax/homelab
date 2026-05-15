{ config, pkgs, ... }:

{
  # Auto-attach to a persistent tmux session named "hermes" on login
  # Ensures laptop and phone always reconnect to the same session
  programs.bash.loginShellInit = ''
    if [[ -z "$TMUX" ]] && [[ "$SSH_CONNECTION" != "" ]]; then
      tmux attach-session -t hermes 2>/dev/null || tmux new-session -s hermes
    fi
  '';

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
