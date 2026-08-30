{ config, lib, vars, pkgs, ... }:

{
  # makes all containers wait for podman-networks service to complete, else they fail since services are being launched in paralel and race condition can happen where
  # container starts before service that creates podman networks.
  systemd.targets.podman-networks = {
    description = "Docker Networks Ready Target";
    after = [ "podman.service" ];
    requires = [ "podman.service" ];
    wantedBy = [ "multi-user.target" ];
  };

  # creates podman networks defined in oci-framework
  systemd.services = (lib.mapAttrs' (containerName: _: {
    name = "podman-${containerName}";
    value = {
      after = [ "podman-networks.target" ];
      requires = [ "podman-networks.target" ];
    };
  }) config.virtualisation.oci-containers.containers) // {

    init-podman-networks = {
      description = "Create global Docker networks";
      before = [ "podman-networks.target" ];
      wantedBy = [ "podman-networks.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        if ! ${pkgs.podman}/bin/podman network inspect macvlan-10 >/dev/null 2>&1; then
          ${pkgs.podman}/bin/podman network create \
	          -d macvlan \
            -o parent=${vars.net.zenki.server-vlan.interface_name} \
            --subnet=${vars.net.sensei.server-vlan.ipv4.subnet}/${vars.net.sensei.server-vlan.ipv4.mask} \
            --gateway=${vars.net.sensei.server-vlan.ipv4.gateway} \
            --ipv6 \
            --subnet=${vars.net.sensei.server-vlan.ipv6.subnet}/${vars.net.sensei.server-vlan.ipv6.mask} \
            --gateway=${vars.net.sensei.server-vlan.ipv6.gateway} \
            macvlan-10
        fi
      '';
    };
  };
}