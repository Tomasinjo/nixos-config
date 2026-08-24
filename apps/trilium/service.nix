{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "trilium";
  serviceHostname = "notes";
  servicePort = 8080;
  serviceId = 34;

  dataDir = "/home/node/trilium-data";

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_gatekeeper { inherit serviceHostname servicePort serviceName serviceId; })
    {
      image = "triliumnext/trilium:v0.104.1";

      environment = {
        "TRILIUM_DATA_DIR" = dataDir;
        "USER_UID" = toString vars.dockerUser.uid;
        "USER_GID" = toString vars.dockerUser.gid;
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/trilium/app-data:${dataDir}"
      ];

      user = ""; # the image support non-root container by passing env variables
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}