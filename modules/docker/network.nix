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

      # Macvlan Network
      # check if it exists first because macvlan settings are immutable
      if ! ${pkgs.docker}/bin/docker network inspect macvlan-10 >/dev/null 2>&1; then
        ${pkgs.docker}/bin/docker network create \
	  -d macvlan \
          -o parent=${vars.networking.zenki.vlan10.interface_name} \
          --subnet=${vars.networking.vlan10.ipv4.subnet} \
          --gateway=${vars.networking.vlan10.ipv4.gateway} \
          --ipv6 \
          --subnet=${vars.networking.vlan10.ipv6.subnet} \
          --gateway=${vars.networking.vlan10.ipv6.gateway} \
          macvlan-10
      fi
    '';
  };
}
