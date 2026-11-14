{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "vaultwarden"; id = 36; dir = ./.; };

  port = 8080;

in
  svc.build {
    app = svc.container {
      web = { 
        host = "bw";
        port = port; 
        expose = "gatekeeper";
      };
      internet = false;
      image = "vaultwarden/server:1.37.5";
      mounts = [ "/data" ];
      environment = {
        "WEBSOCKET_ENABLED" = "true";
        "SIGNUPS_ALLOWED" = "false";
        "INVITATIONS_ALLOWED" = "false";
        "ROCKET_PORT" = toString port;
      };
    };
  }