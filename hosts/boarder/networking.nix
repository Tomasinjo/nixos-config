{ config, pkgs, vars, ... }:

{
  networking.hostName = vars.net.boarder.hostname;
  networking.domain = vars.net.domain;
  
  networking.networkmanager.enable = true;

  networking.firewall = {
    enable = true;
    allowPing = true;
  };
  users.users.${vars.username}.extraGroups = [ "networkmanager" ];
}
