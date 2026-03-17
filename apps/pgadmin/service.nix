{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "pgadmin";
  serviceHostname = "pg";
  servicePort = 80;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort; })
    {
      image = "dpage/pgadmin4:9.13";

      environment = {
        "PGADMIN_DEFAULT_EMAIL" = vars.email.tom;
        "PGADMIN_DEFAULT_PASSWORD" = vars.apps.pgadmin.app.password;
        "MFA_ENABLED" = "false";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/pgadmin/app-data:/var/lib/pgadmin"
      ];

      ports = [];

      networks = [
        "ha-net"
        "fafi-net"
      ];
      
      labels = {};
      dependsOn = [];

      user = "";  # does not support changing uids, runs with uid 5050
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
}