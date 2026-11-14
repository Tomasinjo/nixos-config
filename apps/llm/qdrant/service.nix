{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "qdrant"; id = 28; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "qdrant";
        port = 6333; 
        expose = "internal";
      };
      internet = true;
      image = "ghcr.io/qdrant/qdrant/qdrant:v1.20.1-unprivileged";
      mounts = [
        "storage:/qdrant/storage"
        "snapshots:/qdrant/snapshots"
        "production.yaml:/qdrant/config/production.yaml"
      ];
      environment = {};
      secrets = {};
      #user = "";  # linuxserver image, sets user after startup using env
    };
  }