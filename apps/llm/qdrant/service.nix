{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "qdrant";
  serviceHostname = "qdrant";
  servicePort = 6333;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName; })
    {
      image = "ghcr.io/qdrant/qdrant/qdrant:v1.17.1-unprivileged";

      environment = {};

      volumes = [
        "${vars.dir.nixos_config}/apps/llm/qdrant/app-data/storage:/qdrant/storage"
        "${vars.dir.nixos_config}/apps/llm/qdrant/app-data/snapshots:/qdrant/snapshots"
        "${vars.dir.nixos_config}/apps/llm/qdrant/app-data/production.yaml:/qdrant/config/production.yaml"
      ];

      ports = [];

      networks = [
        "llm-net"
      ];
      
      labels = {};
      dependsOn = [];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
}