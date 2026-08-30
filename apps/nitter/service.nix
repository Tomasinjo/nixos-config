{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "nitter";
  serviceHostname = "x";
  servicePort = 8080;
  serviceId = 38;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_gatekeeper { inherit serviceHostname servicePort serviceName; })
    {
      image = "zedeus/nitter:latest";

      volumes = [
        "${vars.dir.nixos_config}/apps/nitter/app-data/nitter.conf:/src/nitter.conf"
        "${vars.dir.nixos_config}/apps/nitter/app-data/sessions.jsonl:/src/sessions.jsonl:ro"
      ];
    }
  ];

  redisContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.container { inherit serviceName serviceId; containerId = 4; })
    {
      image = "docker.io/library/redis:7.4.10";

      volumes = [
        "${vars.dir.nixos_config}/apps/nitter/redis-data:/data"
      ];
    }
  ];


in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-redis" = redisContainerConfig;

  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}
