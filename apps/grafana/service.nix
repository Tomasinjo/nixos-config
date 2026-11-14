{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "grafana"; id = 18; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "graf";
        port = 3000; 
        expose = "internal";
      };
      internet = true;
      image = "grafana/grafana:13.2.4";
      mounts = [ "/var/lib/grafana" ];
      environment = {
        GF_SERVER_ROOT_URL = "https://graf.${vars.net.domain}/";
        GF_PLUGINS_PREINSTALL = "victoriametrics-metrics-datasource";
      };
      secrets = {};
    };
  }