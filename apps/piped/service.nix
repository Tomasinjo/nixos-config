{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "piped"; id = 41; dir = ./.; };

  dbUser = "piped";
  dbName = "piped";
  backendHostname = "youtube-backend";

in
  svc.build {
    app = svc.container {
      web = { 
        host = "youtube";
        port = 80; 
        expose = "gatekeeper";
      };
      internet = true;
      image = "1337kavin/piped-frontend:latest";
      environment = {
        "BACKEND_HOSTNAME" = "${backendHostname}.${vars.net.domain}";
        "HTTP_MODE" = "https";
      };
      user = ""; # nginx permission denied if not root
      extraOptions = [
        "--sysctl=net.ipv4.ip_unprivileged_port_start=0" # allows binding low ports, nginx uses 80 in container
      ];
    };

    db = svc.db {
      user = dbUser;
      database = dbName;
    };

    backend = svc.container {
      id = 4;
      web = { 
        host = backendHostname;
        port = 8080; 
        expose = "gatekeeper";
      };
      internet = true;
      image = "1337kavin/piped:latest";
      mounts = [ "config.properties:/app/config.properties" ];
      labels = {
        "glance.hide" = "true";
      };
    };

    proxy = svc.container {
      id = 5;
      web = { 
        host = "youtube-proxy";
        port = 8080; 
        expose = "gatekeeper";
      };
      internet = true;
      image = "1337kavin/piped-proxy:latest";
      labels = {
        "glance.hide" = "true";
      };
    };

    bghelper = svc.container {
      id = 6;
      internet = true;
      image = "1337kavin/bg-helper-server:latest";
    };
  }