{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "trilium"; id = 34; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "notes";
        port = 8080; 
        expose = "gatekeeper";
      };
      internet = false;
      image = "triliumnext/trilium:v0.106.1";
      mounts = [ "/home/node/trilium-data" ];
      environment = {
        "TRILIUM_DATA_DIR" = "/home/node/trilium-data";
        "USER_UID" = toString vars.containerUser.uid;
        "USER_GID" = toString vars.containerUser.gid;
      };
      secrets = {};
      user = ""; # the image support non-root container by passing env variables
    };
  }