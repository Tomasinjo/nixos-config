{ inputs ? {}, self ? inputs.self or (throw "get-containers: 'self' argument required"), lib }:

# returns attribute set of oci containers filtered by desired filter
# default val (_: _: true) is empty expression that returns all containers

{ filter ? (_: _: true) }:

let
  zenkiConfig = self.nixosConfigurations.zenki.config;
  containers = zenkiConfig.virtualisation.oci-containers.containers;

in
  lib.filterAttrs filter containers