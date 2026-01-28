{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      dracula-theme.theme-dracula
      rooveterinaryinc.roo-cline # Roo Code
      ms-python.python
      #mgesbert.indent-nested-dictionary
      ms-python.pylint
      ms-vscode-remote.remote-ssh
      ms-vscode-remote.remote-containers
      bbenoist.nix # nix lang support
    ];
  };
}
