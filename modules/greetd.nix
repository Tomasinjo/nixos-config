{ config, pkgs, inputs, vars, ... }:

{
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "${pkgs.hyprland}/bin/Hyprland";
        user = vars.username;
      };
    default_session = initial_session;
    };
  };
}
