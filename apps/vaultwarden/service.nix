{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "vaultwarden";
  serviceHostname = "bw";
  servicePort = 80;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_gatekeeper { inherit serviceHostname servicePort serviceName; })
    {
      image = "vaultwarden/server:1.35.4";

      environment = {
        "WEBSOCKET_ENABLED" = "true";
        "SIGNUPS_ALLOWED" = "false";
        "INVITATIONS_ALLOWED" = "false";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/vaultwarden/app-data:/data"
      ];

      ports = [];
      networks = [];
      labels = {};
      dependsOn = [];
    }
  ];


in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
}