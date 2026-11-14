{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "traefik"; id = 1; dir = ./.; };

in
  svc.build {
    app = svc.container {
      internet = true;  # acme cert renewals
      image = "traefik:v3.7.17";
      mounts = [
        "config:/etc/traefik"
        "plugins:/plugins-storage"  # to set correct permissions. fails to write if non-root
      ];
      environment = {};
      secrets = {
        CF_DNS_API_TOKEN = "ext/cloudflare_api_key";
      };
      dependsOn = [ "dockerproxy-app" ];
      extraOptions = [
        "--sysctl=net.ipv4.ip_unprivileged_port_start=0" # allows binding low ports
      ];
    };

    gatekeeper = svc.container {
      id = 6;
      internet = false;
      image = "ghcr.io/tomasinjo/gatekeeper:main";
      extraMounts = [
        "${vars.dir.nixos_config}/apps/traefik/app-data/config/file_providers/dynamic-whitelist.yml:/app/dynamic-whitelist.yml"
      ];
      environment = {
        MAX_IP_LEN = "10";
        DEFAULT_SOURCE_RANGE = "127.0.0.1/32,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,${vars.net.sensei.ipv6_prefix}";
      };
      labels = {
        "traefik.enable" = "true";
        
        "traefik.http.middlewares.gatekeeper_immich_share.forwardauth.address" = "http://10.0.1.6:5000/verify_share_request?protocol=http&container_name_port=10.0.23.2:2283";
        "traefik.http.middlewares.gatekeeper_immich_share.forwardauth.trustForwardHeader" = "true";
        "traefik.http.middlewares.gatekeeper_immich_share.forwardauth.maxResponseBodySize" = "10485760";

        "traefik.http.middlewares.gatekeeper_opencloud_share.forwardauth.address" = "http://10.0.1.6:5000/verify_share_request?protocol=http&container_name_port=10.0.10.2:9200";
        "traefik.http.middlewares.gatekeeper_opencloud_share.forwardauth.trustForwardHeader" = "true";
        "traefik.http.middlewares.gatekeeper_opencloud_share.forwardauth.maxResponseBodySize" = "10485760";

        "traefik.http.middlewares.gatekeeper_mealie_share.forwardauth.address" = "http://10.0.1.6:5000/verify_share_request?protocol=http&container_name_port=10.0.44.2:9000";
        "traefik.http.middlewares.gatekeeper_mealie_share.forwardauth.trustForwardHeader" = "true";
        "traefik.http.middlewares.gatekeeper_mealie_share.forwardauth.maxResponseBodySize" = "10485760";
      };
    };
  }