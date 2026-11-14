{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "prowlarr"; id = 3; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "prowlarr";
        port = 9696; 
        expose = "internal";
      };
      internet = true; # indexing
      image = "lscr.io/linuxserver/prowlarr:2.7.0.5723-ls166";
      mounts = [ "/config" ];
      user = "";  # linuxserver image, sets user after startup using env
    };
  }