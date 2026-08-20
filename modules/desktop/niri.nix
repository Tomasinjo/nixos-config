{ config, pkgs, inputs, vars, ... }:

{
  imports = [
    ./sound.nix
    ./fonts.nix
    inputs.noctalia-greeter.nixosModules.default
  ];

  programs.niri.enable = true;

  programs.noctalia-greeter = {
    enable = true; 
    greeter-args = "";
    # Full declarative greeter.toml (overwritten on each activation).
    settings = {
      cursor = {
        theme = "Bibata-Modern-Ice";
        size = 24;
        path = "${pkgs.bibata-cursors}/share/icons";
      };
      keyboard = {
        layout = "us";
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
