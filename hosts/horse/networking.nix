{ config, pkgs, vars, ... }:

{
  networking.hostName = "horse";
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    allowPing = true;
  };
  users.users.${vars.username}.extraGroups = [ "networkmanager" ];
}
