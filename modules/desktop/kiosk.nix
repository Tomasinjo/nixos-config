{ config, pkgs, inputs, vars, ... }:

{
  imports = [
    ./sound.nix
    ./fonts.nix
  ];

  services.xserver.enable = false;  # Disable Xorg
  programs.cage.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${pkgs.cage}/bin/cage -- firefox --kiosk \"https://search.${vars.net.domain}\""
      };
    };
  };
}
