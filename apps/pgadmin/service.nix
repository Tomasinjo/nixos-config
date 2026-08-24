{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "pgadmin";
  serviceHostname = "pg";
  servicePort = 80;
  serviceId = 31;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName serviceId; })
    {
      image = "dpage/pgadmin4:9.17";

      environment = {
        "PGADMIN_DEFAULT_EMAIL" = vars.email.tom;
        "PGADMIN_DEFAULT_PASSWORD" = vars.apps.pgadmin.app.password;
        "MFA_ENABLED" = "false";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/pgadmin/app-data:/var/lib/pgadmin"
      ];

      networks = [
        "home-assistant-net"
        "nocodb-net"
      ];

      user = "";  # does not support changing uids, runs with uid 5050
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}