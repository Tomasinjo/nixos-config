{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "appdaemon"; id = 20; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "ad";
        port = 5050; 
        expose = "internal";
      };
      internet = true;  # pip
      image = "acockburn/appdaemon:4.5.16";
      mounts = [ "/conf" ];
      environment = {
        HA_URL = "http://10.0.22.2:8123";
      };
      secrets = {
        HA_KEY = "apps/appdaemon/hass_key";
      };
      user = "";  # can't run without root, fails at installing with pip
      extraOptions = [
        "--cpuset-cpus=12-19"  # eco cores
      ];
    };
  }