{ config, pkgs, inputs, vars, ... }:

{
  imports = [
    ./sound.nix
    ./fonts.nix
  ];

  environment.systemPackages = [ pkgs.cage ]; 

  services.xserver.enable = false;  # Disable Xorg

  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        user = vars.username; 
        # wrap the command to ensure Wayland variables are set
        command = pkgs.writeShellScript "kiosk-script" ''
          export MOZ_ENABLE_WAYLAND=1
          export XDG_SESSION_TYPE=wayland
	  export XCURSOR_SIZE=0
          ${pkgs.cage}/bin/cage -- firefox "https://ha.${vars.net.domain}"
        '';
      };
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd cage";
        user = "greeter";
      };
    };
  };

  users.users.${vars.username}.extraGroups = [ 
    "video"
    "input"
  ];

  # Required for Wayland/Firefox to work correctly with system d-bus
  programs.dconf.enable = true;
}
