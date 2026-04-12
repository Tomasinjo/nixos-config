{ lib, config, pkgs, vars, ... }:

# NOTE:
# Če spreminjas settings.json, prej ugasni container, da ti ne prepiše

# ports:
# 8095 # web
# 8097 # comms with speakers
# 5353/udp # mdns

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "music-assistant";
  serviceHostname = "mass";
  servicePort = 8095;

  appContainerConfig = (oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_gatekeeper { inherit serviceHostname servicePort serviceName; })
    {
      image = "ghcr.io/music-assistant/server:2.8.3";

      environment = {
        "LOG_LEVEL" = "info"; # possible=(critical, error, warning, info, debug, verbose)
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/ha/music_assistant/app-data:/data"
      ];

      ports = [];
      networks = []; # merged later to set specific order

      labels = {
        "traefik.http.services.mass-service.loadbalancer.server.url" = "http://${vars.net.zenki.common-vlan.mac-vlan.mass.ipv4Address}:${toString servicePort}";  # because host mode on macvlan
        "traefik.http.routers.${serviceHostname}.service" = "mass-service";
      };
      dependsOn = [];

      extraOptions = [
        "--ip=${vars.net.zenki.common-vlan.mac-vlan.mass.ipv4Address}"
        "--ip6=${vars.net.zenki.common-vlan.mac-vlan.mass.ipv6Address}"
      ];
    }
  ]) // {
    # Override networks to make macvlan-10 the primary network.
    # This ensures docker applies the --ip and --ip6 options to it instead of traefik-net.
    # Order is important when using --ip option as it only applies to first network in list
    networks = [
      "macvlan-10"
      "ha-net"
      "traefik-net"
    ];
  };

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
}