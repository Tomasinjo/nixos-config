{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "grocy";
  serviceHostname = "grocy";
  servicePort = 80;

  containerConfig = oci-framework.mergeAll [
    oci-framework.base.linuxserver
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName; })
    {
      image = "lscr.io/linuxserver/grocy:v4.5.0-ls316";

      environment = {};

      volumes = [
        "${vars.dir.nixos_config}/apps/grocy/app-data:/config"
      ];

      ports = [];
      networks = [];
      labels = {};
      dependsOn = [];
    }
  ];


in {
  virtualisation.oci-containers.containers."${serviceName}-app" = containerConfig;
}