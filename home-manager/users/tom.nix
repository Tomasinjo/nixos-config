{ hostName, config, pkgs, inputs, ... }:

{
  imports = [
    # Import base modules
    ../../home-manager/modules/packages-base.nix
    ../../home-manager/modules/hyprland-base.nix
    ../../home-manager/modules/waybar-base.nix
    ../../home-manager/modules/hyprlock.nix
    ../../home-manager/modules/yazi.nix
    ../../home-manager/modules/rofi.nix
    ../../home-manager/modules/git.nix
    ../../home-manager/modules/python.nix

    # Import host-specific configuration
    ../../home-manager/hosts/${hostName}/default.nix
  ];

  home.username = "tom";
  home.homeDirectory = "/home/tom";
  home.stateVersion = "25.11";

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  xdg.enable = true; # required by home manager
}

