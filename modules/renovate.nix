{ config, pkgs, lib, vars, ... }:

{
  services.renovate = {
    enable = true;
    schedule = "*-*-* 08:00:00";
    settings = {
      platform = "github";
      gitAuthor = "Renovate Bot <renovate-bot@users.noreply.github.com>";
      autodiscover = true;
      autodiscoverFilter = [ "Tomasinjo/nixos-config" ];
      baseDir = "/var/lib/renovate";
      cacheDir = "/var/cache/renovate";
    };
    environment = {
      RENOVATE_TOKEN = vars.github_pat_nixos;
      GITHUB_COM_TOKEN = vars.github_pat_nixos;

      DOCKER_USERNAME = "tomasinjo";
      DOCKER_PASSWORD = vars.dockerhub_pat;

      DOCKER_GHCR_IO_TOKEN = vars.github_ghcr;

      LOG_LEVEL = "info"; # or "debug"
    };
  };
}