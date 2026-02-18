{ config, pkgs, ... }:

{
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;  
    configFile = ''
      Defaults timestamp_timeout=30  # minutes until sudo timeout
    '';
    extraRules = [{
      users = [ "tom" ];
      commands = [
	{ command = "/run/current-system/sw/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference"; options = [ "NOPASSWD" ]; }  # this allows changing the file without password for user tom
      ];
    }];
  };
}

