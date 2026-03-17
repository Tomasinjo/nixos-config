let
  # Base values
  username = "tom";
  homeDir = "/home/${username}";
  secrets = import ./secrets.nix;
in {
  # User configuration
  inherit username;
  fullName = "Tom";

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
    opencloud.app.admin_password = secrets.apps.opencloud.app.admin_password;
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
  };

  networking = {
    domain = secrets.networking.domain;
    ipv4DNS = secrets.networking.ipv4DNS;
    ipv6DNS = secrets.networking.ipv6DNS;

    vlan10 = {
      ipv4 = {
        subnet =  secrets.networking.vlan10.ipv4.subnet;
        mask = "24";
        gateway = secrets.networking.vlan10.ipv4.gateway;
      };
      ipv6 = {
        subnet =  secrets.networking.vlan10.ipv6.subnet;
        mask = "64";
        gateway = secrets.networking.vlan10.ipv6.gateway;
      };
    };
    ipv6_prefix = secrets.networking.ipv6_prefix;

    zenki = {
      hostname = "zenki";
      fqdn = secrets.networking.zenki.fqdn;
      interface_name = "eth10g";
      interface_mac = secrets.networking.zenki.interface_mac;
      vlan10 = {
        tag = 10;
	      ipv4Address = secrets.networking.zenki.vlan10.ipv4Address;
        ipv6Address = secrets.networking.zenki.vlan10.ipv6Address;
	      interface_name = "eth10g.10";
        mac-vlan = {
          mass = {
            ipv4Address = secrets.networking.zenki.vlan10.mac-vlan.mass.ipv4Address;
            ipv6Address = secrets.networking.zenki.vlan10.mac-vlan.mass.ipv6Address;
          };
          traefik = {
            ipv4Address = secrets.networking.zenki.vlan10.mac-vlan.traefik.ipv4Address;
            ipv6Address = secrets.networking.zenki.vlan10.mac-vlan.traefik.ipv6Address;
          };
        };
      };
    };
    lenko = {
      hostname = "lenko";
    };
    vps = {
      ipv4Address = secrets.networking.vps.ipv4Address;
    };
  };
}