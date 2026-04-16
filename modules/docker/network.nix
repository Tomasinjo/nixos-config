{ pkgs, vars, ... }: 

{
  systemd.services.init-docker-networks = {
    description = "Create global Docker networks";
    after = [ "network.target" "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.docker}/bin/docker network create traefik-net || true
      ${pkgs.docker}/bin/docker network create ha-net || true
      ${pkgs.docker}/bin/docker network create arr-net || true
      ${pkgs.docker}/bin/docker network create fafi-net || true
      ${pkgs.docker}/bin/docker network create llm-net || true
      ${pkgs.docker}/bin/docker network create umami-net || true
      ${pkgs.docker}/bin/docker network create lightdash-net || true
      ${pkgs.docker}/bin/docker network create metabase-net || true
      ${pkgs.docker}/bin/docker network create immich-net || true
      ${pkgs.docker}/bin/docker network create paperless-net || true
      ${pkgs.docker}/bin/docker network create tesla-net || true
      ${pkgs.docker}/bin/docker network create unifi-net || true
      ${pkgs.docker}/bin/docker network create dockerproxy-net || true
      ${pkgs.docker}/bin/docker network create logging-net || true
      ${pkgs.docker}/bin/docker network create cloud-net || true
      ${pkgs.docker}/bin/docker network create fat-net || true
      ${pkgs.docker}/bin/docker network create dawarich-net || true

      # Macvlan Network
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
