{ config, pkgs, vars, ... }:

{
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;  
    configFile = ''
      Defaults timestamp_timeout=30  # minutes until sudo timeout
    '';
    extraRules = [
      {
        users = [ vars.username ];
        commands = [
          {
            command = "/run/current-system/sw/bin/nixos-rebuild"; 
            options = [ "NOPASSWD" ]; # run rebuild without sudo
          }
        ];
      }
    ];
  };
  users.users.${vars.username}.extraGroups = [ "wheel" ];
}

