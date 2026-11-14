{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "pinchflat"; id = 40; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "tube";
        port = 8945; 
        expose = "internal";
      };
      internet = true; # yt downloads
      image = "keglin/pinchflat:v2025.6.6";
      mounts = [ "/config" ];
      extraMounts = [ "${vars.dir.hoarder_data}/media/library/tube:/downloads" ];
      environment = {
        LOG_LEVEL = "info";
      };
    };
  }