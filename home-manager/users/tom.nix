{ hostName, config, pkgs, inputs, vars, ... }:

{
  imports = [
    ../../home-manager/modules/packages-base.nix
    ../../home-manager/modules/git.nix
    ../../home-manager/modules/python.nix
    ../../home-manager/modules/nixvim.nix
    ../../home-manager/modules/zsh.nix

    # host-specific configuration
    ../../home-manager/hosts/${hostName}/default.nix
  ];

  home.username = vars.username;
  home.homeDirectory = vars.dir.home;
  home.stateVersion = "25.11";

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  xdg.enable = true; # required by home manager
}

