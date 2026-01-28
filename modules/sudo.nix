{ config, pkgs, ... }:

{
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;  
    configFile = ''
      Defaults timestamp_timeout=30  # minutes until sudo timeout
    '';
  };
}

