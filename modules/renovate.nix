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
      hostRules = [
        {
          matchHost = "ghcr.io";
          hostType = "docker";
          username = "tomasinjo";
          password = vars.github_ghcr;
        }
        {
          matchHost = "docker.io";
          hostType = "docker";
          username = "tomasinjo";
          password = vars.dockerhub_pat;
        }
      ];
    };
    environment = {
      RENOVATE_TOKEN = vars.github_pat_nixos;
      GITHUB_COM_TOKEN = vars.github_pat_nixos;

      LOG_LEVEL = "debug"; # or "debug"
    };
  };
}