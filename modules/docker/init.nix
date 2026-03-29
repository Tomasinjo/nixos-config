{ pkgs, vars, ... }:

{
  virtualisation.oci-containers.backend = "docker";
  users.users.docker-user = {
    isSystemUser = true;
    group = vars.dockerUser.name;
    uid = vars.dockerUser.uid;
  };
  users.groups.docker-user.gid = vars.dockerUser.gid;
  users.users.${vars.username}.extraGroups = [
    vars.dockerUser.name
  ];

  boot.kernel.sysctl."kernel.perf_event_paranoid" = 0;  # CAP_MON requires this, frigate container  

  imports = [
    ./init_base.nix
    ./network.nix
    ./backup-daily-weekly.nix
    ./backup-quarterly.nix
    ./deploy.nix
    ./vector.nix
    ../../apps/arrs/jellyfin/service.nix
    ../../apps/arrs/pinchflat/service.nix
    ../../apps/arrs/prowlarr/service.nix
    ../../apps/arrs/qbittorrent/service.nix
    ../../apps/arrs/radarr/service.nix
    ../../apps/blog/umami/service.nix
    ../../apps/blog/web_server/service.nix
    ../../apps/fafi/lightdash/service.nix
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
    ../../apps/opencloud/service.nix
    ../../apps/paperless/service.nix
    ../../apps/pgadmin/service.nix
    ../../apps/searxng/service.nix
    ../../apps/teslamate/service.nix
    ../../apps/traefik/service.nix
    ../../apps/trilium/service.nix
    ../../apps/unifi/service.nix
    ../../apps/vaultwarden/service.nix
    ../../apps/victorialogs/service.nix
    ../../apps/kiwix/service.nix
    ../../apps/grafana/service.nix
  ];
}
