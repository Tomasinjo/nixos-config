{ config, pkgs, inputs, vars, ... }:

{
  users.users.${vars.username}.extraGroups = [ 
      "video"
      "audio"
    ];

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # greetd Login Manager
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

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  environment.systemPackages = with pkgs; [
    waybar           # Status bar
    hyprlock         # Screen locker
    dunst            # Notifications
    wl-clipboard     # Copy/Paste support
    brightnessctl    # Brightness control
    playerctl        # Media player control
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    font-awesome
  ];
}
