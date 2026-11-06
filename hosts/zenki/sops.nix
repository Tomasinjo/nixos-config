{ inputs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  sops.secrets = {
    "umami/db/password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "umami/app/secret" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "blog/si/name" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "blog/si/domain" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "blog/en/name" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "blog/en/domain" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "lightdash/minio/user" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "lightdash/minio/password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "lightdash/db/password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "lightdash/app/secret" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "metabase/db/password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "nocodb/db/password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "frigate/rtsp_user" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "frigate/rtsp_password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "mqtt/user" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "mqtt/password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "appdaemon/hass_key" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "esphome/username" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "esphome/password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "home-assistant/db/password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "home-assistant/app/long_lived_token" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "immich/db/password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "open-webui/app/secret" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "opencloud/app/admin_password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "opencloud/app/jwt_secret" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "paperless/app/admin_password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "paperless/app/api_key" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "paperless/app/secret_key" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "paperless/db/password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "pgadmin/app/password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "searxng/app/secret" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "teslamate/app/key" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "teslamate/db/password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "unifi/mongo/password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "unifi/mongo/root_password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "traefik/app/cloudflare_api_key" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "dawarich/app/secret" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "dawarich/db/password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "glance/app/github_token" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "piped/db/password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "degoog/app/setting_password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "hermes/app/glm" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "mealie/db/password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "fatracker/db_password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "fatracker/webhook_api_key" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "fatracker/mcp_api_key" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "fatracker/strong_email" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "fatracker/strong_password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "grocy/api_key" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "grocy/mfp_username" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "grocy/mfp_password" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "grocy/vkj_bearer" = {
      sopsFile = ../../secrets/apps.yaml;
      owner = "podman-svc";
      mode = "0400";
    };



  # network
    "domain" = {
      sopsFile = ../../secrets/network.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "ppoe_username" = {
      sopsFile = ../../secrets/network.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "ppoe_password" = {
      sopsFile = ../../secrets/network.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "ipv6" = {
      sopsFile = ../../secrets/network.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "ipv4" = {
      sopsFile = ../../secrets/network.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "vps_ip" = {
      sopsFile = ../../secrets/network.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "wg/protonvpn_privatekey" = {
      sopsFile = ../../secrets/network.yaml;
      owner = "podman-svc";
      mode = "0400";
    };

  # external
    "github_pat_nixos" = {
      sopsFile = ../../secrets/external.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "github_ghcr" = {
      sopsFile = ../../secrets/external.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "dockerhub_pat" = {
      sopsFile = ../../secrets/external.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "telegram_bot_token" = {
      sopsFile = ../../secrets/external.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
    "telegram_allowed_users" = {
      sopsFile = ../../secrets/external.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
  
  # personal
    "email/tom" = {
      sopsFile = ../../secrets/personal.yaml;
      owner = "podman-svc";
      mode = "0400";
    };
  };
}