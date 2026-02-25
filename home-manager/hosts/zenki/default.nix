{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hyprland.nix
    ./waybar.nix
    ./packages.nix
    ./update-docker.nix
    ../../modules/gaming.nix

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
