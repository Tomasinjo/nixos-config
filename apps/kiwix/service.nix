{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "kiwix";
  serviceHostname = "kb";
  servicePort = 8080;
  serviceId = 25;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName serviceId; })
    {
      image = "ghcr.io/kiwix/kiwix-serve:3.8.2";

      volumes = [
        "${vars.dir.impo_data}/kiwix:/data"
      ];
      
      cmd = ["*.zim"];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}
