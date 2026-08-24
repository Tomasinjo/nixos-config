{ lib, config, pkgs, vars }:

let
  ipPrefix = vars.net.zenki.docker-services.prefix;

  mkIp = serviceId: containerId: "${ipPrefix}.${toString serviceId}.${toString containerId}";
  mkSubnet = serviceId: "${ipPrefix}.${toString serviceId}.0/24";
  mkGateway = serviceId: "${ipPrefix}.${toString serviceId}.1";

  # docker network generator
  mkNetwork = { serviceName, serviceId ? null, subnet ? null, gateway ? null, bridgeName ? null }:
    let
      netName = "${serviceName}-net";
      calcSubnet = if subnet != null then subnet else (if serviceId != null then mkSubnet serviceId else null);
      calcGateway = if gateway != null then gateway else (if serviceId != null then mkGateway serviceId else null);
      
      # minimized to 12 chars + "br-" prefix to respect Linux 15-char IFNAMSIZ limit
      safeBridgeName = if bridgeName != null 
                       then bridgeName 
                       else "br-${builtins.substring 0 12 serviceName}";
    in {
      "network-docker-${netName}" = {
        description = "Create Docker Network: ${netName}";
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        
        before = [ "docker-networks.target" ];
        wantedBy = [ "docker-networks.target" ];
        
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "create-network-${netName}" ''
            ${pkgs.docker}/bin/docker network inspect ${netName} >/dev/null 2>&1 || \
              ${pkgs.docker}/bin/docker network create \
                ${lib.optionalString (calcSubnet != null) "--subnet=${calcSubnet} --gateway=${calcGateway}"} \
                --opt "com.docker.network.bridge.name"="${safeBridgeName}" \
                ${netName}
          '';
        };
      };
    };


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

  merge = base: overrides: 
    let
      baseExtraOpts = lib.subtractLists (overrides.removeExtraOptions or []) (base.extraOptions or []);
      
      merged = base // overrides // {
        volumes = (base.volumes or []) ++ (overrides.volumes or []);
        extraOptions = baseExtraOpts ++ (overrides.extraOptions or []);
        ports = (base.ports or []) ++ (overrides.ports or []);
        dependsOn = (base.dependsOn or []) ++ (overrides.dependsOn or []);
        networks = lib.unique ((base.networks or []) ++ (overrides.networks or []));
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

  # Helper for backend containers (containerId is a REQUIRED integer)
  container = { serviceName, serviceId, containerId }: {
    networks = [ "${serviceName}-net" ];
    extraOptions = [ "--ip=${mkIp serviceId containerId}" ];
  };

  # Helper for databases (containerId defaults to 3)
  db = { serviceName, serviceId, containerId ? 3 }: {
    networks = [ "${serviceName}-net" ];
    extraOptions = [ "--ip=${mkIp serviceId containerId}" ];
  };

  # Web applications (containerId defaults to 2, serviceId optional for macvlan)
  web = {
    base = { 
      serviceHostname, 
      servicePort, 
      serviceName, 
      serviceId ? null, 
      containerId ? 2, 
      customNetworks ? null 
    }: 
    let
      hasRoutedNet = serviceId != null;
    in {
      networks = if customNetworks != null 
                 then customNetworks 
                 else (if hasRoutedNet then [ "${serviceName}-net" "traefik-net" ] else [ "traefik-net" ]);
      
      extraOptions = lib.optional hasRoutedNet "--ip=${mkIp serviceId containerId}";
      
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.${serviceHostname}.rule" = "Host(`${serviceHostname}.${vars.net.domain}`)";
        "traefik.http.routers.${serviceHostname}.entrypoints" = "https,http";
        "traefik.http.routers.${serviceHostname}.tls" = "true";
        "traefik.http.services.${serviceHostname}.loadbalancer.server.port" = toString servicePort;
        "fikus.hostname" = serviceHostname;
        "fikus.name" = serviceName;
        "glance.hide" = "false";
        "glance.name" = lib.concatStringsSep " " (map (s: (lib.toUpper (builtins.substring 0 1 s)) + (builtins.substring 1 (-1) s)) (lib.splitString " " (builtins.replaceStrings ["-"] [" "] serviceName)));
        "glance.url" = "https://${serviceHostname}.${vars.net.domain}";
        "glance.icon" = "di:${serviceName}";
      } // lib.optionalAttrs hasRoutedNet {
        "traefik.docker.network" = "traefik-net";
      };
    };

    internal = args: merge (web.base args) {
      labels = { "traefik.http.routers.${args.serviceHostname}.middlewares" = "internal-whitelist@file"; };
    };
    exposed_gatekeeper = args: merge (web.base args) {
      labels = { "traefik.http.routers.${args.serviceHostname}.middlewares" = "dynamic-whitelist@file"; };
    };
    exposed_mtls = args: merge (web.base args) {
      labels = { "traefik.http.routers.${args.serviceHostname}.tls.options" = "fikus_mtls@file"; };
    };
  };

  # App-specific base configurations
  apps = {
    postgres = { serviceName, serviceId, dbUser, dbPass, dbName, containerId ? 3 }: 
      merge (db { inherit serviceName serviceId containerId; }) {
        image = "postgres:16.14";
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
  inherit 
    core 
    base 
    web 
    db 
    apps 
    container 
    hardware 
    mkNetwork 
    mkIp 
    mkSubnet 
    mkGateway 
    merge 
    mergeAll;
}