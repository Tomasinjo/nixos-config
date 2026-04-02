{ config, pkgs, inputs, vars, ... }:

{
  imports = [
    ./sound.nix
    ./fonts.nix
  ];

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

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

  users.users.${vars.username}.extraGroups = [ 
      "video"
    ];

  environment.systemPackages = with pkgs; [
    dunst            # Notifications
    wl-clipboard     # Copy/Paste support
  ];
}
