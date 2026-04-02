{ config, pkgs, inputs, ... }:

{
  imports = [
    ./packages.nix
    ../../modules/gaming.nix
    ../../modules/desktop/hyprland-base.nix
    ../../modules/desktop/waybar-base.nix
    ../../modules/desktop/hyprlock.nix
    ../../modules/desktop/cursor.nix
    ../../modules/desktop/hyprpaper.nix
    ../../modules/desktop/kitty.nix
    ../../modules/desktop/rofi.nix
  ];

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    shellAliases = {
      set-eco = "echo 'power' | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference";
      set-std = "echo 'balance_performance' | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference";
      set-per = "echo 'performance' | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference";
    };
  };
}
