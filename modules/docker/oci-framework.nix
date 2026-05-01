{ lib, config, vars }:

let
  # The absolute minimums every container should have
  core = {
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
    ];
    log-driver = "json-file";
    capabilities = {
      "NET_RAW" = false;
    };
    environment = {
      "TZ" = vars.timeZone;
    };
    extraOptions = [
      "--security-opt=no-new-privileges:true"
      "--log-opt=max-size=10m"
      "--log-opt=max-file=3"
    ];
  };

  # Helper to merge a base config with service-specific overrides.
  # It safely combines lists (volumes, extraOptions, dependsOn, ports, networks, devices) 
  # and merges attribute sets (environment, labels, capabilities).
  # It supports explicitly removing items from the base extraOptions via `removeExtraOptions`.
  merge = base: overrides: 
    let
      baseExtraOpts = lib.subtractLists (overrides.removeExtraOptions or []) (base.extraOptions or []);
      
      merged = base // overrides // {
        volumes = (base.volumes or []) ++ (overrides.volumes or []);
        extraOptions = baseExtraOpts ++ (overrides.extraOptions or []);
        ports = (base.ports or []) ++ (overrides.ports or []);
        dependsOn = (base.dependsOn or []) ++ (overrides.dependsOn or []);
        networks = (base.networks or []) ++ (overrides.networks or []);
        devices = (base.devices or []) ++ (overrides.devices or []);
        capabilities = (base.capabilities or {}) // (overrides.capabilities or {});
        environment = (base.environment or {}) // (overrides.environment or {});
        labels = (base.labels or {}) // (overrides.labels or {});
      };
    in builtins.removeAttrs merged ["removeExtraOptions"];

  # Helper to merge multiple configs sequentially
  mergeAll = configs: builtins.foldl' merge {} configs;

  # Base execution modes
  base = {
    standard = merge core {
      user = "${toString vars.dockerUser.uid}:${toString vars.dockerUser.gid}";
    };
    
    linuxserver = merge core {
      environment = {
        "PUID" = toString vars.dockerUser.uid;
        "PGID" = toString vars.dockerUser.gid;
      };
    };
  };

  web = {
    base = { serviceHostname, servicePort, serviceName }: {
      networks = [ "traefik-net" ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.${serviceHostname}.rule" = "Host(`${serviceHostname}.${vars.net.domain}`)";
        "traefik.http.routers.${serviceHostname}.entrypoints" = "https,http";
        "traefik.http.routers.${serviceHostname}.tls" = "true";
        "traefik.http.services.${serviceHostname}.loadbalancer.server.port" = toString servicePort;
        "fikus.hostname" = serviceHostname; # custom label for automatic bookmarks
        "fikus.name" = serviceName; # custom label for automatic bookmarks
        "glance.hide" = "false";
        "glance.name" = lib.concatStringsSep " " (map (s: (lib.toUpper (builtins.substring 0 1 s)) + (builtins.substring 1 (-1) s)) (lib.splitString " " (builtins.replaceStrings ["-"] [" "] serviceName)));
        "glance.url" = "https://${serviceHostname}.${vars.net.domain}";
        "glance.icon" = "di:${serviceName}";
      };
    };

    internal = { serviceHostname, servicePort, serviceName }: 
      merge (web.base { inherit serviceHostname servicePort serviceName; }) {
        labels = {
          "traefik.http.routers.${serviceHostname}.middlewares" = "internal-whitelist@file";
        };
      };

    exposed_gatekeeper = { serviceHostname, servicePort, serviceName }: 
      merge (web.base { inherit serviceHostname servicePort serviceName; }) {
        labels = {
          "traefik.http.routers.${serviceHostname}.middlewares" = "dynamic-whitelist@file";
        };
      };
    exposed_mtls = { serviceHostname, servicePort, serviceName }: 
      merge (web.base { inherit serviceHostname servicePort serviceName; }) {
        labels = {
          "traefik.http.routers.${serviceHostname}.tls.options" = "fikus_mtls@file";
        };
      };
  };

  # App-specific base configurations
  apps = {
    postgres = { dbUser, dbPass, dbName }: {
      image = "postgres:16.13";
      environment = {
        POSTGRES_USER = dbUser;
        POSTGRES_PASSWORD = dbPass;
        POSTGRES_DB = dbName;
        PGDATA = "/data/postgres";
      };
      extraOptions = [
        "--shm-size=256m"
        "--stop-timeout=60"
        "--health-cmd=pg_isready -U ${dbUser} -d ${dbName}"
        "--health-interval=1m"
        "--health-timeout=5s"
        "--health-retries=5"
        "--health-start-period=10s"
      ];
    };
  };

  hardware = {
    cuda = {
      devices = [ "nvidia.com/gpu=all" ];
    };
    
    quicksync = {
      devices = [ "${config.hardware.intel-qsv.deviceNode}:${config.hardware.intel-qsv.deviceNode}" ];
      extraOptions = [
        "--group-add=${toString config.hardware.intel-qsv.groupId}"
      ];
    };

    coral = {
      devices = [ "/dev/apex_0:/dev/apex_0" ];
      extraOptions = [
        "--group-add=${if config.users.groups ? coral then toString config.users.groups.coral.gid else "989"}"
      ];
    };
  };

in {
  inherit core base web apps hardware merge mergeAll;
}
