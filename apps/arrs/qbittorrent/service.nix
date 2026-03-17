{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "qbittorrent";
  serviceHostname = "torrent";
  servicePort = 8888;

  torrentingPort = "51413";

  containerConfig = oci-framework.mergeAll [
    oci-framework.base.linuxserver
    (oci-framework.web.internal { inherit serviceHostname servicePort; })
    {
      image = "lscr.io/linuxserver/qbittorrent:5.1.4-r2-ls442";

      environment = {
        "WEBUI_PORT" = toString servicePort;
        "TORRENTING_PORT" = torrentingPort;
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/arrs/qbittorrent/app-data:/config"
        "${vars.dir.hoarder_data}/media:/media"
        "${vars.dir.games}/downloads:/games"
      ];

      ports = [
        "${vars.networking.zenki.vlan10.ipv4Address}:${torrentingPort}:${torrentingPort}/tcp"
        "${vars.networking.zenki.vlan10.ipv4Address}:${torrentingPort}:${torrentingPort}/udp"
      ];

      networks = [
        "arr-net"
      ];
      
      labels = {};
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = containerConfig;
}