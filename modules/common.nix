{ config, pkgs, ... }:

{
  users.users.tom = {
    isNormalUser = true;
    description = "Tom";
    extraGroups = [ 
      "networkmanager" 
      "wheel" 
      "video" 
      "audio" 
      "dialout" # to access /dev/ttyUSB
    ];
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
    wget
    curl
    btop
    tree
    pciutils
    p7zip
  ];

  nixpkgs.config.allowUnfree = true;
}
