{ pkgs, vars, ... }:

{
  virtualisation.oci-containers.backend = "podman";

  virtualisation = {
    podman = {
      enable = true;
      autoPrune.enable = true;
      dockerSocket.enable = true; # creates /var/run/docker.sock, symlinked from podman.sock.
      defaultNetwork.settings = {
        default_subnet = vars.net.zenki.containers.subnet;
        dns_enabled = true;
      };
    };
    containers = {
      enable = true;
      containersConf.settings = {
        containers = {
          log_driver = "journald";
        };
      };
      storage.settings.storage = {
        driver = "overlay";
        graphroot = "/home/tom/containers/storage";
        runroot = "/run/containers/storage";
      };
    };
  };

  environment.systemPackages = [ pkgs.podman-compose pkgs.ctop ];

  users = {
    users.${vars.containerUser.name} = {
      isSystemUser = true;
      group = vars.containerUser.name;
      uid = vars.containerUser.uid;
    };
    groups.${vars.containerUser.name} = {
      gid = vars.containerUser.gid;
    };
    users.${vars.username}.extraGroups = [
      vars.containerUser.name
      "podman"
    ];
  };

  boot.kernel.sysctl."kernel.perf_event_paranoid" = 0;  # CAP_MON requires this, frigate container  

  imports = [
    ./network.nix
    ./backup-daily-weekly.nix
    ./backup-quarterly.nix
    ./deploy.nix
    ./vector.nix
    ./get_networks.nix
    ../../apps/arrs/jellyfin/service.nix
    ../../apps/arrs/pinchflat/service.nix
    ../../apps/arrs/prowlarr/service.nix
    ../../apps/arrs/qbittorrent/service.nix
    ../../apps/arrs/radarr/service.nix
    ../../apps/arrs/sonarr/service.nix
    ../../apps/blog/umami/service.nix
    ../../apps/blog/web_server/service.nix
    ../../apps/dawarich/service.nix
#    ../../apps/fafi/lightdash/service.nix
    ../../apps/fafi/metabase/service.nix
    ../../apps/fafi/nocodb/service.nix
    ../../apps/frigate/service.nix
    ../../apps/grocy/service.nix
    ../../apps/ha/appdaemon/service.nix
    ../../apps/ha/esphome/service.nix
    ../../apps/ha/home_assistant/service.nix
    ../../apps/ha/music_assistant/service.nix
    ../../apps/immich/service.nix
    ../../apps/jupyter/service.nix
    ../../apps/llm/comfyui/service.nix
    ../../apps/llm/open-webui/service.nix
    ../../apps/llm/qdrant/service.nix
    ../../apps/cloud/opencloud/service.nix
    ../../apps/cloud/euro-office/service.nix
    ../../apps/paperless/service.nix
    ../../apps/pgadmin/service.nix
    ../../apps/teslamate/service.nix
    ../../apps/traefik/service.nix
    ../../apps/trilium/service.nix
    ../../apps/unifi/service.nix
    ../../apps/vaultwarden/service.nix
    ../../apps/victorialogs/service.nix
    ../../apps/kiwix/service.nix
    ../../apps/grafana/service.nix
    ../../apps/glance/service.nix
    ../../apps/openshot/service.nix
    ../../apps/degoog/service.nix
    ../../apps/nitter/service.nix
  ];
}
