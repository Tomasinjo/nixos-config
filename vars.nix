let
  username = "tom";
  homeDir = "/home/${username}";
  secrets = import ./secrets.nix;
in {
  inherit username;
  fullName = "Tom";

  net = (import ./net.nix { inherit secrets; }).net;

  dir = {
    home = homeDir;
    nixos_config = "${homeDir}/nixos-config";
    hoarder_data = "/hoarder-data";
    impo_data = "/impo-data";
    games = "/games_mx500";
    usb_mountpoint = "${homeDir}/mnt";
    scripts = "${homeDir}/scripts";
    certs = "${homeDir}/certs";
    docker_root = "${homeDir}/docker";
  };

  email = {
    tom = secrets.email.tom;
  };

  timeZone = "Europe/Ljubljana";

  dockerUser = {
    name = "docker-user";
    uid = 1111;
    gid = 1111;
  };

  apps = {
    umami = {
      db.password = secrets.apps.umami.db.password;
      app.secret = secrets.apps.umami.app.secret;
    };
    blog = {
      si = {
        name = secrets.apps.blog.si.name;
        domain = secrets.apps.blog.si.domain;
      };
      en = {
        name = secrets.apps.blog.en.name;
        domain = secrets.apps.blog.en.domain;
      };
    };
    lightdash = {
      minio = {
        user = secrets.apps.lightdash.minio.user;
        password = secrets.apps.lightdash.minio.password;
      };
      db.password = secrets.apps.lightdash.db.password;
      lightdash.secret = secrets.apps.lightdash.lightdash.secret;
    };
    metabase.db.password = secrets.apps.metabase.db.password;
    nocodb.db.password = secrets.apps.nocodb.db.password;
    frigate = {
      rtsp_user = secrets.apps.frigate.rtsp_user;
      rtsp_password = secrets.apps.frigate.rtsp_password;
    };
    mqtt = {
      user = secrets.apps.mqtt.user;
      password = secrets.apps.mqtt.password;
    };
    appdaemon = {
      hass_key = secrets.apps.appdaemon.hass_key;
    };
    esphome = {
      username = secrets.apps.esphome.username;
      password = secrets.apps.esphome.password;
    };
    home-assistant.db.password = secrets.apps.home-assistant.db.password;
    immich.db.password = secrets.apps.immich.db.password;
    open-webui.app.secret = secrets.apps.open-webui.app.secret;
    opencloud.app = {
      admin_password = secrets.apps.opencloud.app.admin_password;
      jwt_secret = secrets.apps.opencloud.app.jwt_secret;
    };
    paperless = {
      app = {
        admin_password = secrets.apps.paperless.app.admin_password;
        api_key = secrets.apps.paperless.app.api_key;
      };
      db.password = secrets.apps.paperless.db.password;
    };
    pgadmin.app.password = secrets.apps.pgadmin.app.password;
    searxng.app.secret = secrets.apps.searxng.app.secret;
    teslamate = {
      app.key = secrets.apps.teslamate.app.key;
      db.password = secrets.apps.teslamate.db.password;
    };
    unifi.mongo = {
      password = secrets.apps.unifi.mongo.password;
      root_password = secrets.apps.unifi.mongo.root_password;
    };
    traefik.app.cloudflare_api_key = secrets.apps.traefik.app.cloudflare_api_key;
    fatracker.db.password = secrets.apps.fatracker.db.password;
    dawarich = {
      app.secret = secrets.apps.dawarich.app.secret;
      db.password = secrets.apps.dawarich.db.password;
    };
    glance.app.github_token = secrets.apps.glance.app.github_token;
  };
}