{ lib, config, pkgs, vars, ... }:

# Note: Has DNAT rule from internet on sensei, port 51413

let
  oci = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "qbittorrent"; id = 4; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "torrent";
        port = 8888; 
        expose = "gatekeeper";
      };
      internet = true; # connecting to peers
      image = "lscr.io/linuxserver/qbittorrent:5.1.4-r3-ls453";
      mounts = [ "/config" ];
      extraMounts = [
        "${vars.dir.hoarder_data}/media:/media"
        "${vars.dir.games}/downloads:/games"
      ];
      environment = {
        WEBUI_PORT = "8888";
        TORRENTING_PORT = "51413";
      };
      user = "";  # linuxserver image, sets user after startup using env
    };
  }