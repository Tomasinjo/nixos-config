{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "openshot"; id = 29; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "openshot";
        port = 3000; 
        expose = "internal";
      };
      internet = false;
      image = "lscr.io/linuxserver/openshot:v3.5.1-ls66";
      mounts = [ "/config" ];
      environment = {
        PIXELFLUX_WAYLAND = "true";
        DRINODE = "/dev/dri/renderD128";
        DRI_NODE = "/dev/dri/renderD128";
      };
      hardware = [ "quicksync" ];
    };
  }