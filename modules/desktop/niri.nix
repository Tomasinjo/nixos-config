{ config, pkgs, inputs, vars, ... }:

{
  imports = [
    ./sound.nix
    ./fonts.nix
  ];

  programs.niri.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd ${pkgs.niri}/bin/niri-session";
        user = "greeter";
      };
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
