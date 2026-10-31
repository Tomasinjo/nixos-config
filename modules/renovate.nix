{ config, pkgs, lib, vars, inputs, ... }:

{
  services.renovate = {
    enable = true;

    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.renovate;

    # needed for flake.lock maintenance
    runtimePackages = [ pkgs.nix ];

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

      # use the list api instead of tag listings (ignores auth, too many requests errors)
      RENOVATE_X_DOCKER_HUB_TAGS_DISABLE = "1";

      LOG_LEVEL = "info"; # info or debug
    };
  };
}