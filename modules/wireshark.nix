{ config, pkgs, vars, ... }:

{

  programs.wireshark = {
    enable = true;
    dumpcap.enable = true;
  };

  users.users.${vars.username}.extraGroups = [ "wireshark" ];
}
