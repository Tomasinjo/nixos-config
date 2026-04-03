{ config, pkgs, vars, ... }:

{
  environment.systemPackages = [ pkgs.wireshark ];

  programs.wireshark = {
    enable = true;
    dumpcap.enable = true;
  };

  users.users.${vars.username}.extraGroups = [ "wireshark" ];
}
