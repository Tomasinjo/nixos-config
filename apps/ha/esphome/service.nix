{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "esphome"; id = 21; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "eh"; 
        port = 6052;
        expose = "internal";
      };
      internet = true;
      image = "esphome/esphome:2026.10.2";
      mounts = [ "/config" ];
      environment = { 
        ESPHOME_DASHBOARD_USE_PING = "true"; 
      };
      secrets = { 
        USERNAME = "apps/esphome/username"; 
        PASSWORD = "apps/esphome/password"; 
      };
      user = ""; # fails if run as user: PermissionError: [Errno 13] Permission denied: '/.platformio'
    };
  }