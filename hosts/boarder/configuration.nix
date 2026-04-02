{ config, pkgs, inputs, vars, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ../../modules/common.nix
    ../../modules/shell.nix
    ../../modules/desktop.nix
    ../../modules/greetd.nix
    ../../modules/sudo.nix
    ../../modules/utilities.nix
    ../../modules/ssh.nix
  ];

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  hardware.bluetooth.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    ddcutil  # for setting brightness via ssh commands from home assistant
  ];

  system.stateVersion = "25.11";
}
