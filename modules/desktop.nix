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

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  environment.systemPackages = with pkgs; [
    dunst            # Notifications
    wl-clipboard     # Copy/Paste support
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    font-awesome
  ];
}
