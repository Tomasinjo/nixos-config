{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "vaultwarden";
  serviceHostname = "bw";
  servicePort = 8080;
  serviceId = 36;

  appContainerConfig = oci-framework.mergeAll [
    (oci-framework.web.exposed_gatekeeper { inherit serviceName serviceId serviceHostname servicePort; })
    {
      image = "vaultwarden/server:1.37.1";

      environment = {
        "WEBSOCKET_ENABLED" = "true";
        "SIGNUPS_ALLOWED" = "false";
        "INVITATIONS_ALLOWED" = "false";
        "ROCKET_PORT" = toString servicePort;
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/vaultwarden/app-data:/data"
      ];
    }
  ];


in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}