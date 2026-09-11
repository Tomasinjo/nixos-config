{ lib, config, pkgs, vars }:

let
  ipPrefix = vars.net.zenki.containers.prefix;
  ip6Prefix = vars.net.zenki.containers.prefix6;

  # use serviceid to determine the ipv6 network
  formatService6 = serviceId: toString (1000 + serviceId);
  # create static ipv4 address 
  mkIp = serviceId: containerId: "${ipPrefix}.${toString serviceId}.${toString containerId}";
  # create static ipv6 address  - aaaa:aaaa:aaaa:ff00:1XXX::Y)
  mkIp6 = serviceId: containerId: "${ip6Prefix}:${formatService6 serviceId}::${toString containerId}";

  # generates systemd services that create dual stack podman network with static ips
  mkNetwork = { 
    serviceName, 
    serviceId, 
    isInternal ? false 
  }:
    let
      netName = "${serviceName}-net";
      subnet4 =  "${ipPrefix}.${toString serviceId}.0/24";
      gateway4 = "${ipPrefix}.${toString serviceId}.1";

      subnet6 =  "${ip6Prefix}:${formatService6 serviceId}::/80";
      gateway6 = "${ip6Prefix}:${formatService6 serviceId}::1";
      
      safeBridgeName = "br-${builtins.substring 0 12 serviceName}";
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
                "--subnet=${subnet4} --gateway=${gateway4}" \
                "--ipv6 --subnet=${subnet6} --gateway=${gateway6}" \
                --interface-name="${safeBridgeName}" \
                ${netName}
          '';
        };
      };
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



  core = { serviceName, serviceId, containerId, requiresInternet ? "false" }: {
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
    ];
    log-driver = "journald";
    capabilities = {
      "NET_RAW" = false;
    };
    environment = {
      "TZ" = vars.timeZone;
      "PUID" = toString vars.containerUser.uid; # for linuxserver images
      "PGID" = toString vars.containerUser.gid; # for linuxserver images
    };
    user = "${toString vars.containerUser.uid}:${toString vars.containerUser.gid}"; # must be overrided to empty string for linuxserver images
    extraOptions = [
      "--security-opt=no-new-privileges:true"
      "--log-opt=max-size=10m"
      "--log-opt=max-file=3"
    ];
    networks = [ "${serviceName}-net:ip=${mkIp serviceId containerId},ip6=${mkIp6 serviceId containerId}" ];
    labels = {
      "glance.name" = lib.concatStringsSep " " (map (s: (lib.toUpper (builtins.substring 0 1 s)) + (builtins.substring 1 (-1) s)) (lib.splitString " " (builtins.replaceStrings ["-"] [" "] serviceName)));
      "glance.icon" = "di:${serviceName}";
      "glance.hide" = "true";
      "requires.internet" = requiresInternet; # evaluated by sensei to allow outbound connections
      "address.ipv4" = mkIp  serviceId containerId;
      "address.ipv6" = mkIp6 serviceId containerId;
    };
  };


  # Web applications (containerId defaults to 2)
  web = {
    base = { 
      serviceName,
      serviceId,
      serviceHostname,
      servicePort,
      containerId ? 2,
      requiresInternet ? "false"
    }: merge (core { inherit serviceName serviceId containerId requiresInternet; }) {
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.${serviceHostname}.rule" = "Host(`${serviceHostname}.${vars.net.domain}`)";
        "traefik.http.routers.${serviceHostname}.entrypoints" = "https,http";
        "traefik.http.routers.${serviceHostname}.tls" = "true";
        "traefik.http.services.${serviceHostname}.loadbalancer.server.port" = toString servicePort;
        "glance.hide" = "false";
        "glance.url" = "https://${serviceHostname}.${vars.net.domain}";
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
    postgres = {
      serviceName, 
      serviceId, 
      dbUser, 
      dbPass, 
      dbName, 
      containerId ? 3,
      requiresInternet ? "false"
    }: merge (core { inherit serviceName serviceId containerId requiresInternet; }) {
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
    web 
    apps 
    hardware 
    mkNetwork 
    merge 
    mergeAll;
}