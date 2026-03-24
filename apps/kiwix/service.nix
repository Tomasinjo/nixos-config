{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "kiwix";
  serviceHostname = "kb";
  servicePort = 8080;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort; })
    {
      image = "ghcr.io/kiwix/kiwix-serve:3.8.2";

      environment = {};

      volumes = [
        "${vars.dir.impo_data}/kiwix:/data"
      ];

      ports = [];
      networks = [];
      labels = {};
      dependsOn = [];
      
      cmd = ["*.zim"];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
}
