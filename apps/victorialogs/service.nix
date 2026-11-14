{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "victoriametrics"; id = 37; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "logs";
        port = 9428; 
        expose = "internal";
      };
      internet = false;
      image = "docker.io/victoriametrics/victoria-logs:v1.54.0";
      mounts = [ "/victoria-logs-data" ];
      cmd = [
        "-storageDataPath=victoria-logs-data"
      ];
    };
  }
