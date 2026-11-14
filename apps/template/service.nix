# special configs:
# - teslamate: two webapps
# - dawarich: custom database
# - blog/web_server: web app that does not use wrapper in oci-framework.nix

# if container needs to talk with other containers, add allow entry to networking.nix nftables on zenki
# if it requires access to any internal network/host add entry to nftables in sensei
# if it needs internet access, set internet = true;


{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework2.nix { inherit lib config pkgs vars; };
  # oci = import ../../../modules/podman/oci-framework2.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = ""; id = ; dir = ./.; };
  # id is third octet of subnet, must be unique!
  # find current highest: echo 'Current highest serviceId:' && ip a | sed -nE 's/.*inet 10\.0\.([0-9.]+)\..*/\1/p' | sort -n | tail -n 1
  # name is container's base name, usually service name. It gets appended with role e.g. servicename-app, servicename-db etc

  dbUser = "";
  dbName = "";

# variable name ("app") is container role and is used for:
# container name, for example servicename-app
# mounts, it will construct host side directory for example .../app-data/, .../db-data/
# set container ID, parameter "id" which is fourth octet in static IP. app=2, db=3. Can be omitted for these two.

# mounts can be used in following ways:
# [ "/config" ], will translate to <absolute path to service>/<role>-data:/config
# [ "config:/config" ], will translate to <absolute path to service>/<role>-data/config:/config
# do not use leading / on host side
# do not use :ro, not supported

# extraMounts are normal mounts, directly merged to oci-containers volumes

# secrets: value is path of sops secret, see sops.nix
# when saving db password, make sure to use standard path: "<servicename>/db/password"
# when set like that, it will automatically pass it to postgres password env var.

in
  svc.build {
    app = svc.container { 
      web = { 
        host = "";
        port = ; 
        expose = "internal";
        #expose = "gatekeeper";
        #expose = "mtls";
        #expose = "plain";
      };
      internet = false;
      image = "";
      mounts = [];
      #extraMounts = [];
      environment = {
        DATABASE_HOST = svc.containerName "db";
      };
      secrets = { 
        ENCRYPTION_KEY = "apps/XXXX/app/key";
      };
      # autoStart = false;  # use for rarely used service, systemd service must be manually started:
      # entrypoint = "/bin/sh";
      # cmd = [ "executable" "--flag" "flag_val" ]; # same as "command" compose directive
      # extraOptions = [];
      # hardware = [ "cuda" "quicksync" "coral" ]
    };

    # seconday service
    secondary = svc.container {
      id = 4;
      #web = {};
      internet = false;
      image = "";
      mounts = [ "/var/lib/grafana" ];
      environment = {
      };
      secrets = { 
        DATABASE_PASS = "apps/XXXX/db/password";
      };
      labels = {};
    };

    # assumes sops directory <service name>/db/password
    db = svc.db {
      user = dbUser;
      database = dbName;
    };
  }



## Simple service
{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../../modules/podman/oci-framework2.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = ""; id = ; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "";
        port = ; 
        expose = "internal";
      };
      internet = true;
      image = "";
      mounts = [ "" ];
      environment = {};
      secrets = {};
      #user = "";  # linuxserver image, sets user after startup using env
    };
  }