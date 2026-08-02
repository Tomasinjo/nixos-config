{ config, pkgs, vars, ... }:

{
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  users.users.${vars.username} = {
    extraGroups = [ "uinput" ];
  };
  
  hardware.uinput.enable = true;
}



