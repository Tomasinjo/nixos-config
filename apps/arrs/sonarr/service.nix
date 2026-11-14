{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "sonarr"; id = 6; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "sonarr";
        port = 8989; 
        expose = "gatekeeper";
      };
      internet = true; # for imdb 
      image = "lscr.io/linuxserver/sonarr:4.0.20.3014-ls329";
      mounts = [ "/config" ];
      extraMounts = [ "${vars.dir.hoarder_data}/media:/media" ];
      user = "";  # linuxserver image, sets user after startup using env
    };
  }