{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "qbittorrent";
  serviceHostname = "torrent";
  servicePort = 8888;
  serviceId = 4;

  # Note: Has DNAT rule from internet on sensei, port 51413

  containerConfig = oci-framework.mergeAll [
    oci-framework.base.linuxserver
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName serviceId; })
    {
      image = "lscr.io/linuxserver/qbittorrent:5.1.4-r3-ls453";

      environment = {
        "WEBUI_PORT" = toString servicePort;
        "TORRENTING_PORT" = "51413";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/arrs/qbittorrent/app-data:/config"
        "${vars.dir.hoarder_data}/media:/media"
        "${vars.dir.games}/downloads:/games"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = containerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}