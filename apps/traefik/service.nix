{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "";
  serviceHostname = "";
  servicePort = 0;

  appContainerConfig = (oci-framework.mergeAll [
    oci-framework.base.standard
    {
      image = "traefik:v3.6.11";

      environment = {};

      volumes = [
        "${vars.dir.nixos_config}/apps/traefik/app-data:/etc/traefik"
        "${vars.dir.nixos_config}/apps/traefik/app-data:/plugins-storage"  # to set correct permissions. fails to write if non-root
      ];

      ports = [];
      networks = [];
      labels = {};

      dependsOn = [ "dockerproxy" ];

      extraOptions = [
        "--sysctl=net.ipv4.ip_unprivileged_port_start=0" # allows binding low ports
        "--ip=${vars.net.zenki.common-vlan.mac-vlan.traefik.ipv4Address}"
        "--ip6=${vars.net.zenki.common-vlan.mac-vlan.traefik.ipv6Address}"
      ];
    }
  ]) // {
    # Override networks to make macvlan-10 the primary network.
    # This ensures docker applies the --ip and --ip6 options to it instead of traefik-net.
    # Order is important when using --ip option as it only applies to first network in list
    networks = [
      "macvlan-10"
      "dockerproxy-net"
      "traefik-net"
    ];
  };



  dockerproxyContainerConfig = oci-framework.mergeAll [
    {
      image = "wollomatic/socket-proxy:1.11.4";

      environment = {};

      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock:ro"
      ];

      ports = [];

      networks = [
        "traefik-net"
        "dockerproxy-net"
      ];
      
      labels = {};
      dependsOn = [];

      user = "65534:131";  # 131 is docker gid

      extraOptions = [
        "--read-only"
        "--memory=64M"
        "--cap-drop=ALL"
        "--security-opt=no-new-privileges:true"
      ];

      cmd = [
        "-loglevel=info"
        "-allowfrom=traefik"
        "-listenip=0.0.0.0"
        "-allowGET=/v1\..{1,2}/(version|containers/.*|events.*)" # this regexp allows readonly access only for requests that traefik needs
        "-allowHEAD=/_ping"
        "-shutdowngracetime=5"
        "-watchdoginterval=600"
        "-stoponwatchdog"
      ];
    }
  ];

  gatekeeperContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    {
      image = "ghcr.io/tomasinjo/gatekeeper:main";

      environment = {
        "MAX_IP_LEN" = "10";
        "DEFAULT_SOURCE_RANGE" = "127.0.0.1/32,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,${vars.net.sensei.ipv6_prefix}";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/traefik/app-data/file_providers/dynamic-whitelist.yml:/app/dynamic-whitelist.yml"
      ];

      ports = [];

      networks = [
        "traefik-net"
      ];
      
      labels = {
        "traefik.enable" = "true";
        "traefik.http.middlewares.gatekeeper_immich_share.forwardauth.address" = "http://gatekeeper:5000/verify_share_request?protocol=http&container_name_port=immich-app:2283";
        "traefik.http.middlewares.gatekeeper_immich_share.forwardauth.trustForwardHeader" = "true";
        "traefik.http.middlewares.gatekeeper_opencloud_share.forwardauth.address" = "http://gatekeeper:5000/verify_share_request?protocol=http&container_name_port=opencloud-app:9200";
        "traefik.http.middlewares.gatekeeper_opencloud_share.forwardauth.trustForwardHeader" = "true";
      };
      dependsOn = [];
    }
  ];



in {
  virtualisation.oci-containers.containers."traefik" = appContainerConfig;
  virtualisation.oci-containers.containers."dockerproxy" = dockerproxyContainerConfig;
  virtualisation.oci-containers.containers."gatekeeper" = gatekeeperContainerConfig;
}