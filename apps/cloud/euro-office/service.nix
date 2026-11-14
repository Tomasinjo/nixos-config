{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "euro-office"; id = 9; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "office";
        port = 80; 
        expose = "gatekeeper";
      };
      internet = false;
      image = "ghcr.io/euro-office/documentserver:v9.3.8";
      environment = {
        "WOPI_ENABLED" = "true";
        "USE_UNAUTHORIZED_STORAGE" = "false";
      };
      user = "";  # does not support non-root
    };
  }