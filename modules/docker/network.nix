{ pkgs, vars, ... }:

{
  systemd.services.init-docker-networks = {
    description = "Create Docker Routed Subnets";
    after = [ "network.target" "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      # Ingress Traefik Network (serviceId = 1)
      ${pkgs.docker}/bin/docker network inspect traefik-net >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create \
          --subnet=10.200.1.0/24 \
          --gateway=10.200.1.1 \
          --opt "com.docker.network.bridge.name"="br-traefik" \
          traefik-net

      # Immich Network (serviceId = 10)
      ${pkgs.docker}/bin/docker network inspect immich-net >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create \
          --subnet=10.200.10.0/24 \
          --gateway=10.200.10.1 \
          --opt "com.docker.network.bridge.name"="br-immich" \
          immich-net

      # Vaultwarden Network (serviceId = 30)
      ${pkgs.docker}/bin/docker network inspect vaultwarden-net >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create \
          --subnet=10.200.30.0/24 \
          --gateway=10.200.30.1 \
          --opt "com.docker.network.bridge.name"="br-vaultwarden" \
          vaultwarden-net

      # Home Assistant Network (serviceId = 40)
      ${pkgs.docker}/bin/docker network inspect ha-net >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create \
          --subnet=10.200.40.0/24 \
          --gateway=10.200.40.1 \
          --opt "com.docker.network.bridge.name"="br-ha" \
          ha-net

      # ARR Stack Network (serviceId = 50)
      ${pkgs.docker}/bin/docker network inspect arr-net >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create \
          --subnet=10.200.50.0/24 \
          --gateway=10.200.50.1 \
          --opt "com.docker.network.bridge.name"="br-arr" \
          arr-net

      # Paperless Network (serviceId = 60)
      ${pkgs.docker}/bin/docker network inspect paperless-net >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create \
          --subnet=10.200.60.0/24 \
          --gateway=10.200.60.1 \
          --opt "com.docker.network.bridge.name"="br-paperless" \
          paperless-net

      # Unifi Network (serviceId = 70)
      ${pkgs.docker}/bin/docker network inspect unifi-net >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create \
          --subnet=10.200.70.0/24 \
          --gateway=10.200.70.1 \
          --opt "com.docker.network.bridge.name"="br-unifi" \
          unifi-net

      # TeslaMate Network (serviceId = 80)
      ${pkgs.docker}/bin/docker network inspect tesla-net >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create \
          --subnet=10.200.80.0/24 \
          --gateway=10.200.80.1 \
          --opt "com.docker.network.bridge.name"="br-tesla" \
          tesla-net

      # FAFI Stack Network (serviceId = 90)
      ${pkgs.docker}/bin/docker network inspect fafi-net >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create \
          --subnet=10.200.90.0/24 \
          --gateway=10.200.90.1 \
          --opt "com.docker.network.bridge.name"="br-fafi" \
          fafi-net

      # LLM Stack Network (serviceId = 100)
      ${pkgs.docker}/bin/docker network inspect llm-net >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create \
          --subnet=10.200.100.0/24 \
          --gateway=10.200.100.1 \
          --opt "com.docker.network.bridge.name"="br-llm" \
          llm-net

      # Blog Stack Network (serviceId = 110)
      ${pkgs.docker}/bin/docker network inspect umami-net >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create \
          --subnet=10.200.110.0/24 \
          --gateway=10.200.110.1 \
          --opt "com.docker.network.bridge.name"="br-umami" \
          umami-net

      # Dawarich Network (serviceId = 120)
      ${pkgs.docker}/bin/docker network inspect dawarich-net >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create \
          --subnet=10.200.120.0/24 \
          --gateway=10.200.120.1 \
          --opt "com.docker.network.bridge.name"="br-dawarich" \
          dawarich-net

      # Cloud Stack Network (serviceId = 130)
      ${pkgs.docker}/bin/docker network inspect cloud-net >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create \
          --subnet=10.200.130.0/24 \
          --gateway=10.200.130.1 \
          --opt "com.docker.network.bridge.name"="br-cloud" \
          cloud-net

      # Fatracker Network (serviceId = 140)
      ${pkgs.docker}/bin/docker network inspect fat-net >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create \
          --subnet=10.200.140.0/24 \
          --gateway=10.200.140.1 \
          --opt "com.docker.network.bridge.name"="br-fat" \
          fat-net

      # Logging Network (serviceId = 150)
      ${pkgs.docker}/bin/docker network inspect logging-net >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create \
          --subnet=10.200.150.0/24 \
          --gateway=10.200.150.1 \
          --opt "com.docker.network.bridge.name"="br-logging" \
          logging-net

      # Dockerproxy Network (serviceId = 160)
      ${pkgs.docker}/bin/docker network inspect dockerproxy-net >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create \
          --subnet=10.200.160.0/24 \
          --gateway=10.200.160.1 \
          --opt "com.docker.network.bridge.name"="br-dockerproxy" \
          dockerproxy-net

      # Macvlan Network (bypasses routed supernet)
      # check if it exists first because macvlan settings are immutable
      if ! ${pkgs.docker}/bin/docker network inspect macvlan-10 >/dev/null 2>&1; then
        ${pkgs.docker}/bin/docker network create \
	  -d macvlan \
          -o parent=${vars.net.zenki.common-vlan.interface_name} \
          --subnet=${vars.net.sensei.common-vlan.ipv4.subnet}/${vars.net.sensei.common-vlan.ipv4.mask} \
          --gateway=${vars.net.sensei.common-vlan.ipv4.gateway} \
          --ipv6 \
          --subnet=${vars.net.sensei.common-vlan.ipv6.subnet}/${vars.net.sensei.common-vlan.ipv6.mask} \
          --gateway=${vars.net.sensei.common-vlan.ipv6.gateway} \
          macvlan-10
      fi
    '';
  };
}
