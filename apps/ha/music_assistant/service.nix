{ lib, config, pkgs, vars, ... }:

# NOTE:
# Če spreminjas settings.json, prej ugasni container, da ti ne prepiše

# ports:
# 8095 # web
# 8097 # comms with speakers
# 5353/udp # mdns

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "music-assistant";
  serviceHostname = "mass";
  servicePort = 8095;
  serviceId = 39;

  appContainerConfig = (oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_gatekeeper {inherit serviceHostname servicePort serviceName serviceId; })
    {
      image = "ghcr.io/music-assistant/server:2.9.13";

      environment = {
        "LOG_LEVEL" = "info"; # possible=(critical, error, warning, info, debug, verbose)
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/ha/music_assistant/app-data:/data"
      ];
    }
  ]);

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}
