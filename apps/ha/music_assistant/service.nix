{ lib, config, pkgs, vars, ... }:

# NOTE:
# Če spreminjas settings.json, prej ugasni container, da ti ne prepiše

# ports:
# 8095 # web
# 8097 # comms with speakers
# 5353/udp # mdns

let
  oci = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "music-assistant"; id = 39; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "mass";
        port = 8095; 
        expose = "gatekeeper";
      };
      internet = true;  # internet radio
      image = "ghcr.io/music-assistant/server:2.10.9";
      mounts = [ "/data" ];
      environment = {
        "LOG_LEVEL" = "info"; # possible = critical, error, warning, info, debug, verbose
      };
    };
  }