{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "qdrant";
  serviceHostname = "qdrant";
  servicePort = 6333;
  serviceId = 28;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName serviceId; })
    {
      image = "ghcr.io/qdrant/qdrant/qdrant:v1.19.0-unprivileged";

      volumes = [
        "${vars.dir.nixos_config}/apps/llm/qdrant/app-data/storage:/qdrant/storage"
        "${vars.dir.nixos_config}/apps/llm/qdrant/app-data/snapshots:/qdrant/snapshots"
        "${vars.dir.nixos_config}/apps/llm/qdrant/app-data/production.yaml:/qdrant/config/production.yaml"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}