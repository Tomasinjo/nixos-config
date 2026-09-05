{ lib, config, pkgs, vars, ... }:

# special configs:
# - teslamate: two webapps
# - dawarich: custom database
# - blog/web_server: web app that does not use wrapper in oci-framework.nix

# if container needs to talk with other containers, add allow entry to networking.nix nftables on zenki
# if it requires access to any internal network or internet, add entry to nftables in sensei

let
  oci-framework = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "";
  serviceHostname = "";
  servicePort = ;
  serviceId = 0;
  # ^^^ this is third octet of subnet, must be unique!
  # find current highest: echo 'Current highest serviceId:' && ip a | sed -nE 's/.*inet 10\.0\.([0-9.]+)\..*/\1/p' | sort -n | tail -n 1

  dbUser = "";
  dbPass = vars.apps.;
  dbName = "";

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    #(oci-framework.container { inherit serviceName serviceId; containerId = 4; }) # use for any non-web, non-db containers. IDs 2 (web) and 3 (db) are reserved! This is used to pass over service and container IDs which generate static IP for container
    #oci-framework.base.linuxserver
    #(oci-framework.web.base { inherit serviceHostname servicePort serviceName serviceId; })
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName serviceId; })
    #(oci-framework.web.exposed_gatekeeper { inherit serviceHostname servicePort serviceName serviceId; })
    #(oci-framework.web.exposed_mtls { inherit serviceHostname servicePort serviceName serviceId; })
    #oci-framework.hardware.cuda
    #oci-framework.hardware.quicksync
    {
      image = "";

      environment = {};

      volumes = [
        "${vars.dir.nixos_config}/apps/xxx/app-data:"
      ];

      labels = {};
      
      # Do not use ports = [];     # available directly on exposed static IP
      # Do not use networks = [];  # handled by OCI containers

      #dependsOn = [ "${serviceName}-db" ];  # DO NOT USE IT - backup will stop the db service and with it the dependency, which will not be restarted afterwards.

      # optional and overrides
      #entrypoint = "/example.sh";
      #user = "";

      #removeExtraOptions = [ "--security-opt=no-new-privileges:true" ];

      #extraOptions = [
      #  "--security-opt=no-new-privileges:false" # override the base compose - wont start without it, says it cant access /r
      #  "--tmpfs=/dev/shm:mode=770,uid=1111,gid=1111,size=268435456"
      #  "--tmpfs=/tmp/cache:mode=770,uid=1111,gid=1111,size=1G"
      #  "--cpuset-cpus=12-19"  # eco cores
      #];

      # use for rarely used service, systemd service must be manually started:
      # autoStart = false;

      # same as "command" compose directive
      #cmd = [
      #  "-loglevel=info"
      #  "-allowfrom=traefik"
      #];

      # FQDN: ${serviceHostname}.${vars.net.domain}
      # IP ${vars.net.zenki.server-vlan.ipv4Address}
    }
  ];

  dbContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.apps.postgres { inherit serviceName serviceId dbUser dbPass dbName; })
    # or instead of above, if this is non-standard DB, then use the following which assigns it ID of 2 (last octet in static ip):
    (oci-framework.db { inherit serviceName serviceId; })
    {
      volumes = [
        "${vars.dir.nixos_config}/apps/xxxx/db-data:/data/postgres"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-db" = dbContainerConfig;

  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}
