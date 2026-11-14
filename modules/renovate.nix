{ config, pkgs, lib, vars, inputs, ... }:

{
  services.renovate = {
    enable = true;

    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.renovate;

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
          password = "{{ env.GHCR_TOKEN }}";
        }
        {
          matchHost = "lscr.io";
          hostType = "docker";
          username = "tomasinjo";
          password = "{{ env.GHCR_TOKEN }}";
        }
        {
          matchHost = "docker.io";
          hostType = "docker";
          username = "tomasinjo";
          password = "{{ env.DOCKERHUB_PAT }}";
        }
      ];
    };
    environment = {
      # use the list api instead of tag listings (ignores auth, too many requests errors)
      RENOVATE_X_DOCKER_HUB_TAGS_DISABLE = "1";
      LOG_LEVEL = "info"; # info or debug
    };

    credentials = {
      RENOVATE_TOKEN   = config.sops.secrets."ext/github_pat_nixos".path;
      GITHUB_COM_TOKEN = config.sops.secrets."ext/github_pat_nixos".path;
      GHCR_TOKEN       = config.sops.secrets."ext/github_ghcr".path;
      DOCKERHUB_PAT    = config.sops.secrets."ext/dockerhub_pat".path;
    };
  };
}
