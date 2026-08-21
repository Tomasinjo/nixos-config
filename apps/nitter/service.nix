{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "nitter";
  serviceHostname = "x";
  servicePort = 8080;


  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_gatekeeper { inherit serviceHostname servicePort serviceName; })
    {
      image = "zedeus/nitter:latest";

      environment = {};

      volumes = [
        "${vars.dir.nixos_config}/apps/nitter/app-data/nitter.conf:/src/nitter.conf"
        "${vars.dir.nixos_config}/apps/nitter/app-data/sessions.jsonl:/src/sessions.jsonl:ro"
      ];

      ports = [];

      networks = [
        "nitter-net"
      ];
      
      labels = {};
      dependsOn = [];
    }
  ];

  redisContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    {
      image = "docker.io/library/redis:7.4.10";

      environment = {};

      volumes = [
        "${vars.dir.nixos_config}/apps/nitter/redis-data:/data"
      ];

      ports = [];

      networks = [
        "nitter-net"
      ];
      
      labels = {};
    }
  ];


in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-redis" = redisContainerConfig;
}
