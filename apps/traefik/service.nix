{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  serviceId = 1;
  serviceName = "traefik";

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.container { inherit serviceName serviceId; containerId = 2; }) 
    {
      image = "traefik:v3.7.11";

      environment = {
        CF_DNS_API_TOKEN = vars.apps.traefik.app.cloudflare_api_key;
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/traefik/app-data:/etc/traefik"
        "${vars.dir.nixos_config}/apps/traefik/app-data:/plugins-storage"  # to set correct permissions. fails to write if non-root
      ];

      dependsOn = [ "dockerproxy" ];

      networks = [
        "dockerproxy-net"
      ];

      extraOptions = [
        "--sysctl=net.ipv4.ip_unprivileged_port_start=0" # allows binding low ports
      ];
    }
  ];


  dockerproxyContainerConfig = oci-framework.mergeAll [
    {
      image = "wollomatic/socket-proxy:1.12.3";

      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock:ro"
      ];

      networks = [
        "dockerproxy-net"
      ];
      
      # run as root so it can read /var/run/docker.sock
      user = "0:0";

      extraOptions = [
        "--read-only"
        "--memory=64M"
        "--cap-drop=ALL"
        "--security-opt=no-new-privileges:true"
      ];

      cmd = [
        "-loglevel=info"
        "-allowfrom=traefik,glance-app"
        "-listenip=0.0.0.0"
        "-allowGET=/(v1\..{1,2}/)?(version|containers/.*|events.*)"  # this regexp allows readonly access only for requests from traefik and glance 
        "-allowHEAD=/_ping"
        "-shutdowngracetime=5"
        "-watchdoginterval=600"
        "-stoponwatchdog"
      ];
    }
  ];

  gatekeeperContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.container { serviceName = "traefik"; inherit serviceId; containerId = 6; })
    {
      image = "ghcr.io/tomasinjo/gatekeeper:main";

      environment = {
        "MAX_IP_LEN" = "10";
        "DEFAULT_SOURCE_RANGE" = "127.0.0.1/32,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,${vars.net.sensei.ipv6_prefix}";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/traefik/app-data/file_providers/dynamic-whitelist.yml:/app/dynamic-whitelist.yml"
      ];

      labels = {
        "traefik.enable" = "true";
        "traefik.http.middlewares.gatekeeper_immich_share.forwardauth.address" = "http://10.0.1.6:5000/verify_share_request?protocol=http&container_name_port=immich-app:2283";
        "traefik.http.middlewares.gatekeeper_immich_share.forwardauth.trustForwardHeader" = "true";
        "traefik.http.middlewares.gatekeeper_immich_share.forwardauth.maxResponseBodySize" = "10485760";
        "traefik.http.middlewares.gatekeeper_opencloud_share.forwardauth.address" = "http://10.0.1.6:5000/verify_share_request?protocol=http&container_name_port=opencloud-app:9200";
        "traefik.http.middlewares.gatekeeper_opencloud_share.forwardauth.trustForwardHeader" = "true";
        "traefik.http.middlewares.gatekeeper_opencloud_share.forwardauth.maxResponseBodySize" = "10485760";
      };
    }
  ];

in {
  virtualisation.oci-containers.containers."traefik" = appContainerConfig;
  virtualisation.oci-containers.containers."dockerproxy" = dockerproxyContainerConfig;
  virtualisation.oci-containers.containers."gatekeeper" = gatekeeperContainerConfig;

  systemd.services = lib.mkMerge [
    # Creates traefik-net (10.0.1.0/24), 1001::/64
    (oci-framework.mkNetwork {
      serviceName = "traefik";
      inherit serviceId; # 10.0.1.0/24
    })
    
    # Creates dockerproxy-net (Internal bridge)
    (oci-framework.mkNetwork {
      serviceName = "dockerproxy";
      serviceId = 200;
      isInternal = true; # created with --internal (no internet/routing gateway)
    })
  ];
}