{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "degoog"; id = 12; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "search";
        port = 4444; 
        expose = "gatekeeper";
      };
      internet = true; # search engines
      image = "ghcr.io/degoog-org/degoog:1.1.1";
      mounts = [ "/app/data" ];
      environment = {
        DEGOOG_DISTRUST_PROXY = "0";
      };
      secrets = {
        DEGOOG_SETTINGS_PASSWORDS = "apps/degoog/app/setting_password";
      };
      user = "";
    };
  }