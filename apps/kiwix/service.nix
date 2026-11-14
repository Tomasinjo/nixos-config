{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "kiwix"; id = 25; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "kb";
        port = 8080; 
        expose = "internal";
      };
      internet = false;
      image = "ghcr.io/kiwix/kiwix-serve:3.8.2";
      mounts = [];
      extraMounts = [ "${vars.dir.impo_data}/kiwix:/data" ];
      environment = {};
      secrets = {};
      cmd = ["*.zim"];
    };
  }