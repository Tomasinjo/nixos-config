{ config, pkgs, ... }:

{
  users.users.tom = {
    isNormalUser = true;
    description = "Tom";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    shell = pkgs.zsh;
    uid = 1000;
  };

  time.timeZone = "Europe/Ljubljana";
  i18n.defaultLocale = "en_US.UTF-8";

  # Keyboard layout
  services.xserver.xkb.layout = "si";
 console.keyMap = "slovene";


  nix.gc = {   # delete old generations
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true; # Saves space by de-duplicating files
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    btop
    tree
    rsync
    pciutils
    p7zip
    ripgrep
  ];

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
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      scan_timeout = 1000;
      };
    };
  };
  nixpkgs.config.allowUnfree = true;
}
