{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "radarr"; id = 5; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "radarr";
        port = 7878; 
        expose = "gatekeeper";
      };
      internet = true; # for imdb 
      image = "lscr.io/linuxserver/radarr:6.4.4.10685-ls326";
      mounts = [ "/config" ];
      extraMounts = [ "${vars.dir.hoarder_data}/media:/media" ];
      user = "";  # linuxserver image, sets user after startup using env
    };
  }