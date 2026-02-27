{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    virt-manager
  ];

  virtualisation = {  
    spiceUSBRedirection.enable = true;
  };
}


