{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "unifi";
  serviceHostname = "unifi";
  servicePort = 8443;

  mongoUser = "unifi";
  mongoPass = vars.apps.unifi.mongo.password;
  mongoName = "unifi";

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.linuxserver
    (oci-framework.web.internal { inherit serviceHostname servicePort; })
    {
      image = "lscr.io/linuxserver/unifi-network-application:10.1.85-ls118";

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

      ports = [
        "${vars.networking.zenki.vlan10.ipv4Address}:3478:3478/udp"  # STUN
        "${vars.networking.zenki.vlan10.ipv4Address}:8080:8080"      # Port used for device and application communication.
        # "${vars.networking.zenki.vlan10.ipv4Address}:10001:10001/udp" # Port used for device discovery.
        # "${vars.networking.zenki.vlan10.ipv4Address}:1900:1900/udp"   # Port used for "Make application discoverable on L2 network" in the UniFi Network settings.
        # "${vars.networking.zenki.vlan10.ipv4Address}:8843:8843"       # Port used for application GUI/API as seen in a web browser
        # "${vars.networking.zenki.vlan10.ipv4Address}:8880:8880"       # Port used for HTTP portal redirection.
        # "${vars.networking.zenki.vlan10.ipv4Address}:6789:6789"       # Port used for UniFi mobile speed test.
        # "${vars.networking.zenki.vlan10.ipv4Address}:5514:5514/udp"   # Port used for remote syslog capture.
      ];

      networks = [
        "unifi-net"
      ];
      
      labels = {
        "traefik.http.services.${serviceHostname}.loadbalancer.server.scheme" = "https";
        "traefik.http.routers.${serviceHostname}.middlewares" = "unifiHeaders@file,internal-whitelist@file";
      };

      dependsOn = [ "${serviceName}-db" ];
    }
  ];

  dbContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    {
      image = "mongo:8.2";

      environment = {
        "MONGO_INITDB_ROOT_USERNAME" = "root";
        "MONGO_INITDB_ROOT_PASSWORD" = vars.apps.unifi.mongo.root_password;
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/unifi/db-data:/data/db"
      ];

      networks = [
        "unifi-net"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-db" = dbContainerConfig;
}