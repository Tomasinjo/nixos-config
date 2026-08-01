{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    defaultKeymap = "emacs";
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "colored-man-pages" "extract" ];
    };
    history = {
      path = "${config.home.homeDirectory}/.histfile";
      size = 10000;
      save = 10000;
      ignoreDups = true;
    };
    initContent = ''
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

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd cd" ];  # Replace cd with zoxide
  };
  
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      update_check = false;
    };
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    icons = "auto";
  };

  programs.zsh.shellAliases = {
    ls = "eza";
    ll = "eza -la";
    la = "eza -a";
    l = "eza -l";
    cat = "bat";
    };

  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      pager = "less -FR";
    };
  };


  programs.starship = {
    enable = true;
    enableZshIntegration = true;
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
