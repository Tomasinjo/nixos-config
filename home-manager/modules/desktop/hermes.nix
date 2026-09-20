{ inputs, pkgs, ... }:

{
  imports = [
    inputs.hermes-agent.homeManagerModules.default
  ];

  programs.hermes-agent = {
    enable = true;
    desktop = {
      enable = true;
    };
  };
}
