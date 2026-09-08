{ lib, config, pkgs, vars, ... }:

# special configs:
# - teslamate: two webapps
# - dawarich: custom database
# - blog/web_server: web app that does not use wrapper in oci-framework.nix

# if container needs to talk with other containers, add allow entry to networking.nix nftables on zenki
# if it requires access to any internal network/host add entry to nftables in sensei
# if it needs internet access, set requiresInternet = true;

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
    # Use only when other options do not apply. usually containerId should be 4 or higher.
    #(oci-framework.core { inherit serviceName serviceId; containerId = 4; })
    
    # web based containers, pick one
    #(oci-framework.web.base { inherit serviceName serviceId serviceHostname servicePort; })
    #(oci-framework.web.internal { inherit serviceName serviceId serviceHostname servicePort; })
    #(oci-framework.web.exposed_gatekeeper { inherit serviceName serviceId serviceHostname servicePort; })
    #(oci-framework.web.exposed_mtls { inherit serviceName serviceId serviceHostname servicePort; })
    
    # For containers that need access to hardware, use in combination with core or web
    #oci-framework.hardware.cuda
    #oci-framework.hardware.quicksync
    #oci-framework.hardware.coral

    # If container requires internet access. Works for web based containers as well:
    #(oci-framework.core { 
    #  inherit serviceName serviceId; containerId = 4;
    #  requiresInternet = true;
    #})

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
      #user = "";  # containers that dont support running as non root, and for linuxserver images (env set in core)

      #removeExtraOptions = [ "--security-opt=no-new-privileges:true" ];  # to remove options set by oci-framework, rare, used in frigate

      #extraOptions = [
      #  "--security-opt=no-new-privileges:false"
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
    (oci-framework.apps.postgres { inherit serviceName serviceId dbUser dbPass dbName; })
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
