{ config, pkgs, inputs, ... }:

{
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    xwayland.enable = true;
  };

  # greetd Login Manager
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "start-hyprland";
        user = "tom";
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
    hyprpaper        # Wallpaper
    wl-clipboard     # Copy/Paste support
    brightnessctl    # Brightness control
    playerctl        # Media player control
  ];


  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    font-awesome
  ];
}
