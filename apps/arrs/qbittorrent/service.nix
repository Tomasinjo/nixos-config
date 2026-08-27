{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "qbittorrent";
  serviceHostname = "torrent";
  servicePort = 8888;
  serviceId = 4;

  torrentingPort = "51413";

  containerConfig = oci-framework.mergeAll [
    oci-framework.base.linuxserver
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName serviceId; })
    {
      image = "lscr.io/linuxserver/qbittorrent:5.1.4-r3-ls453";

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
        "${vars.net.zenki.server-vlan.ipv4Address}:${torrentingPort}:${torrentingPort}/tcp"
        "${vars.net.zenki.server-vlan.ipv4Address}:${torrentingPort}:${torrentingPort}/udp"
      ];
      
      labels = {};
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = containerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}