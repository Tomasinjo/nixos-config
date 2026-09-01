{ lib, config, pkgs, vars }:

let
  ipPrefix = vars.net.zenki.containers.prefix;
  ip6Prefix = vars.net.zenki.containers.prefix6;

  # use serviceid to determine the ipv6 network
  formatService6 = serviceId: toString (1000 + serviceId);

  # ipv4 helpers
  mkIp = serviceId: containerId: "${ipPrefix}.${toString serviceId}.${toString containerId}";
  mkSubnet = serviceId: "${ipPrefix}.${toString serviceId}.0/24";
  mkGateway = serviceId: "${ipPrefix}.${toString serviceId}.1";

  # ipv6 helpers - aaaa:aaaa:aaaa:ff00:1XXX::Y)
  mkIp6 = serviceId: containerId: "${ip6Prefix}:${formatService6 serviceId}::${toString containerId}";
  mkSubnet6 = serviceId: "${ip6Prefix}:${formatService6 serviceId}::/80";
  mkGateway6 = serviceId: "${ip6Prefix}:${formatService6 serviceId}::1";

  # generates systemd services that create dual stack podman network
  mkNetwork = { 
    serviceName, 
    serviceId ? null, 
    subnet ? null, 
    gateway ? null, 
    ipv6Subnet ? null, 
    ipv6Gateway ? null, 
    bridgeName ? null,
    isInternal ? false 
  }:
    let
      netName = "${serviceName}-net";
      calcSubnet = if subnet != null then subnet else (if serviceId != null then mkSubnet serviceId else null);
      calcGateway = if gateway != null then gateway else (if serviceId != null then mkGateway serviceId else null);

      hasV6 = serviceId != null && (vars.net.zenki.containers ? prefix6);
      calcSubnet6 = if ipv6Subnet != null then ipv6Subnet else (if hasV6 then mkSubnet6 serviceId else null);
      calcGateway6 = if ipv6Gateway != null then ipv6Gateway else (if hasV6 then mkGateway6 serviceId else null);
      
      safeBridgeName = if bridgeName != null 
                       then bridgeName 
                       else "br-${builtins.substring 0 12 serviceName}";
    in {
      "network-podman-${netName}" = {
        description = "Create Dual-Stack Podman Network: ${netName}";
        after = [ "network.target" ];
        before = [ "podman-networks.target" ];
        wantedBy = [ "podman-networks.target" ];
        
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "create-network-${netName}" ''
            ${pkgs.podman}/bin/podman network inspect ${netName} >/dev/null 2>&1 || \
              ${pkgs.podman}/bin/podman network create \
                ${lib.optionalString isInternal "--internal"} \
                ${lib.optionalString (calcSubnet != null) "--subnet=${calcSubnet} --gateway=${calcGateway}"} \
                ${lib.optionalString (calcSubnet6 != null) "--ipv6 --subnet=${calcSubnet6} --gateway=${calcGateway6}"} \
                --interface-name="${safeBridgeName}" \
                ${netName}
          '';
        };
      };
    };


  core = {
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
    ];
    log-driver = "journald";
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
      "--replace" # replace old container, also reclaims assigned IP
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
      user = "${toString vars.containerUser.uid}:${toString vars.containerUser.gid}";
    };
    
    linuxserver = merge core {
      environment = {
        "PUID" = toString vars.containerUser.uid;
        "PGID" = toString vars.containerUser.gid;
      };
    };
  };

  # Helper for backend containers (containerId is a REQUIRED integer)
  container = { serviceName, serviceId, containerId }: {
    networks = [ "${serviceName}-net:ip=${mkIp serviceId containerId},ip6=${mkIp6 serviceId containerId}" ];
  };

  # Helper for databases (containerId defaults to 3)
  db = { serviceName, serviceId, containerId ? 3 }: {
    networks = [ "${serviceName}-net:ip=${mkIp serviceId containerId},ip6=${mkIp6 serviceId containerId}" ];
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
      primaryNet = if hasRoutedNet 
                   then "${serviceName}-net:ip=${mkIp serviceId containerId},ip6=${mkIp6 serviceId containerId}" 
                   else "${serviceName}-net";
    in {
      networks = if customNetworks != null then customNetworks else [ primaryNet ];
            
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