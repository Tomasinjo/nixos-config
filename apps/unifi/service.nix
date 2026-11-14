{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "unifi"; id = 35; dir = ./.; };

  # controller settings
  #set-inform http://10.0.35.2:8080/inform

  mongoUser = "unifi";
  mongoName = "unifi";
  hostname = "unifi";

in
  svc.build {
    app = svc.container {
      web = { 
        host = hostname;
        port = 8443; 
        expose = "internal";
      };
      internet = false;
      image = "lscr.io/linuxserver/unifi-network-application:10.6.109-ls152";
      mounts = [ "/config" ];
      #extraMounts = [];
      environment = {
        MONGO_USER = mongoUser;
        MONGO_HOST = svc.containerName "db";
        MONGO_PORT = "27017";
        MONGO_DBNAME = mongoName;
        MONGO_AUTHSOURCE = "admin";
      };
      secrets = { 
        MONGO_PASS = "apps/unifi/mongo/password";
      };
      labels = {
        "traefik.http.services.${hostname}.loadbalancer.server.scheme" = "https";
        "traefik.http.routers.${hostname}.middlewares" = "unifiHeaders@file,internal-whitelist@file";
      };
      user = "";  # linuxserver image, sets user after startup using env
    };

    db = svc.container {
      id = 3;
      internet = false;
      image = "mongo:8.3";
      mounts = [ "/data/db" ];
      environment = {
        MONGO_INITDB_ROOT_USERNAME = "root";
      };
      secrets = { 
        MONGO_INITDB_ROOT_PASSWORD = "apps/unifi/mongo/root_password";
      };
    };
  }