{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    interactiveShellInit = ''
      export HISTFILE=~/.histfile
      export HISTSIZE=1000
      export SAVEHIST=1000
      setopt HIST_IGNORE_DUPS
      bindkey -e
      bindkey '\e[3~' delete-char

      bindkey '^H'      backward-kill-word         # C-Backspace
      bindkey '5~'      kill-word                  # C-Del
      bindkey '^[[3;5~' kill-word                  # C-Del
      bindkey '^[[3^'   kill-word                  # C-Del

      bindkey '^[[1;5C' forward-word               # C-Right
      bindkey '^[0c'    forward-word               # C-Right
      bindkey '^[[5C'   forward-word               # C-Right

      bindkey '^[[1;5D' backward-word              # C-Left
      bindkey '^[0d'    backward-word              # C-Left
      bindkey '^[[5D'   backward-word              # C-Left
      '';
  };
  
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      line_break.disabled = true;
      scan_timeout = 30;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
    };
  };
}
