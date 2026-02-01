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
