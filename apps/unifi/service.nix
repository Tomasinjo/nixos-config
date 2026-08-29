{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "unifi";
  serviceHostname = "unifi";
  servicePort = 8443;
  serviceId = 35;

  # controller settings
  #set-inform http://10.0.35.2:8080/inform

  mongoUser = "unifi";
  mongoPass = vars.apps.unifi.mongo.password;
  mongoName = "unifi";

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.linuxserver
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName serviceId; })
    {
      image = "lscr.io/linuxserver/unifi-network-application:10.5.67-ls141";

      environment = {
        "MONGO_USER" = mongoUser;
        "MONGO_PASS" = mongoPass;
        "MONGO_HOST" = "${serviceName}-db";
        "MONGO_PORT" = "27017";
        "MONGO_DBNAME" = mongoName;
        "MONGO_AUTHSOURCE" = "admin";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/unifi/app-data:/config"
      ];
      
      labels = {
        "traefik.http.services.${serviceHostname}.loadbalancer.server.scheme" = "https";
        "traefik.http.routers.${serviceHostname}.middlewares" = "unifiHeaders@file,internal-whitelist@file";
      };
    }
  ];

  dbContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.db { inherit serviceName serviceId; })
    {
      image = "mongo:8.3";

      environment = {
        "MONGO_INITDB_ROOT_USERNAME" = "root";
        "MONGO_INITDB_ROOT_PASSWORD" = vars.apps.unifi.mongo.root_password;
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/unifi/db-data:/data/db"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-db" = dbContainerConfig;

  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}