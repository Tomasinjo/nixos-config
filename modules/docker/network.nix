{ config, lib, vars, ... }:

{
  networking.firewall = {
    enable = true;
    checkReversePath = "loose"; # important for asymmetric routed container traffic

    trustedInterfaces = [ "docker0" ];

    extraCommands = ''
      # Allow traffic between docker bridges (br-*) and the physical VLAN interface
      iptables -I FORWARD -i br-+ -j ACCEPT
      iptables -I FORWARD -o br-+ -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
      iptables -I INPUT -i br-+ -j ACCEPT

      # Disable SNAT so docker containers use their static ip for outbound traffic
      iptables -t nat -I POSTROUTING 1 -s ${vars.net.zenki.docker-services.subnet} ! -d ${vars.net.zenki.docker-services.subnet} -j ACCEPT
    '';
  };

  # makes all containers wait for docker-networks service to complete, else they fail since services are being launched in paralel and race condition can happen where
  # container starts before service that creates docker networks.
  systemd.targets.docker-networks = {
    description = "Docker Networks Ready Target";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
  };

  # creates docker networks defined in oci-framework
  systemd.services = lib.mapAttrs' (containerName: _: {
    name = "docker-${containerName}";
    value = {
      after = [ "docker-networks.target" ];
      requires = [ "docker-networks.target" ];
    };
  }) config.virtualisation.oci-containers.containers;
}
