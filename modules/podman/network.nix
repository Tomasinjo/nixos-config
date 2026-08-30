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
  }) config.virtualisation.oci-containers.containers);
}