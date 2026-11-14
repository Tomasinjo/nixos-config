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

  # default container ids by role (app and db follow the network conventions)
  idRoles = { app = 2; db = 3; };

  # passed thru "hardware" array argument.
  # only devices and extraOptions are currently implemented
  # these presets are then merged to coresponding oci-containers.containers args
  hardwarePresets = {
    cuda.devices = [ "nvidia.com/gpu=all" ];

    quicksync = {
      devices = [ "${config.hardware.intel-qsv.deviceNode}:${config.hardware.intel-qsv.deviceNode}" ];
      extraOptions = [ "--group-add=${toString config.hardware.intel-qsv.groupId}" ];
    };

    coral = {
      devices = [ "/dev/apex_0:/dev/apex_0" ];
      extraOptions = [ "--group-add=${if config.users.groups ? coral then toString config.users.groups.coral.gid else "989"}" ];
    };
  };

  service = { name, 
              id,  # service id is used for third octet of ipv4
              dir, # always pass "./."
              internal ? false 
            }:
    let
      serviceId = id;

      # livedir example:
      # "./." is passed as dir from service.nix, evaluates to /nix/store/abasdasda...-source/apps/ha/appdaemon
      # reporoot is  /nix/store/abasdasda...-source which is removed from dir
      # livedir = "/home/tom/nixos-config" + "/apps/ha/appdaemon"
      repoRoot = toString ../..;
      liveDir = vars.dir.nixos_config + lib.removePrefix repoRoot (toString dir);

      glanceName = lib.concatStringsSep " " (map (s: (lib.toUpper (builtins.substring 0 1 s)) + (builtins.substring 1 (-1) s)) (lib.splitString " " (lib.replaceStrings ["-"] [" "] name)));

      # systemd oneshot creating the dual-stack network with static ips
      mkNetwork = {
        "network-podman-${name}-net" = {
          description = "Create Dual-Stack Podman Network: ${name}-net";
          after = [ "network.target" ];
          before = [ "podman-networks.target" ];
          wantedBy = [ "podman-networks.target" ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "create-network-${name}-net" ''
              ${pkgs.podman}/bin/podman network inspect ${name}-net >/dev/null 2>&1 || \
                ${pkgs.podman}/bin/podman network create \
                  ${lib.optionalString internal "--internal"} \
                  --subnet=${ipPrefix}.${toString serviceId}.0/24 --gateway=${ipPrefix}.${toString serviceId}.1 \
                  --ipv6 --subnet=${ip6Prefix}:${formatService6 serviceId}::/80 --gateway=${ip6Prefix}:${formatService6 serviceId}::1 \
                  --interface-name="br-${builtins.substring 0 12 name}" \
                  ${name}-net
            '';
          };
        };
      };

      container = { image, 
                    id ? null,  # use if role is not app or db
                    web ? null, # map, use for web apps, takes host (hostname), port [int], expose (possible vals internal (default),gatekeeper,mtls,plain)
                    internet ? false,
                    environment ? {},
                    secrets ? {},
                    mounts ? [], # short mount, "/config" resolves to "{role}-data":/config. "subdir:/config" becomes "{role}-data/subdir":/config"
                    extraMounts ? [], # oci-containers volumes compliant mount, merged to volumes 
                    hardware ? [],    # array of hardware presets to use, currently cuda, quicksync, coral
                    extraNetworks ? [], 
                    labels ? {}, 
                    extraOptions ? [], 
                    noNewPrivileges ? true, 
                    user ? "${toString vars.containerUser.uid}:${toString vars.containerUser.gid}", 
                    cmd ? [], 
                    entrypoint ? null, 
                    ports ? [],   # no need to use this
                    devices ? [], # non-preset device
                    dependsOn ? [], 
                    autoStart ? true, 
                    capabilities ? {}
                   }: role:
        let
          containerId = if id != null then id else idRoles.${role} or
            (throw "service '${name}': container '${role}' needs an explicit id");
          cname = "${name}-${role}";

          # this argument is simplified mount
          # input: /container becomes  <liveDir>/<role>-data:/container
          # input: sub/dir:/container becomes <liveDir>/<role>-data/sub/dir:/container
          # if specifing host dir, then do not use trailing /
          mount = entry:
            let
              parts = lib.splitString ":" entry;
              # if no ":" (parts is 1 item), then optionalString evals to "", returns item as it is. If two items, append "/" before first item
              sub = lib.optionalString (builtins.length parts > 1) "/${lib.head parts}"; 
            in
              assert lib.hasPrefix "/" (lib.last parts); # fails if not leading / on container part, required
              "${liveDir}/${role}-data${sub}:${lib.last parts}";

          hw = map (h: hardwarePresets.${h} or (throw "service '${name}': unknown hardware '${h}'")) hardware;

          # web app containers, creates labels with traefik config
          # merges with oci-containers.container.labels
          # only if optional web arg is provided
          webLabels =
            if web == null then {}
            else
              let
                exposure = {
                  internal = { "traefik.http.routers.${web.host}.middlewares" = "internal-whitelist@file"; };
                  gatekeeper = { "traefik.http.routers.${web.host}.middlewares" = "dynamic-whitelist@file"; };
                  mtls = { "traefik.http.routers.${web.host}.tls.options" = "fikus_mtls@file"; };
                  plain = {};
                };
              in {
                "traefik.enable" = "true";
                "traefik.docker.network" = "${name}-net";
                "traefik.http.routers.${web.host}.rule" = "Host(`${web.host}.${vars.net.domain}`)";
                "traefik.http.routers.${web.host}.entrypoints" = "https,http";
                "traefik.http.routers.${web.host}.tls" = "true";
                "traefik.http.services.${web.host}.loadbalancer.server.port" = toString web.port;
                "glance.hide" = "false";
                "glance.url" = "https://${web.host}.${vars.net.domain}";
              } // exposure.${web.expose or "internal"}
                  or (throw "service '${name}': unknown web.expose '${web.expose}' (internal|gatekeeper|mtls|plain)");

          # rendered at activation by sops-nix; placeholder values are the
          # ${<sops key>} markers sops-install-secrets substitutes at render time
          template =
            if secrets == {} then null
            else {
              content = lib.concatStringsSep "\n"
                (lib.mapAttrsToList (envVar: key: "${envVar}=${config.sops.placeholder."${key}"}") secrets) + "\n";
              restartUnits = [ "podman-${cname}.service" ]; # restart service if secret was changed, required so new env files are loaded. 
            };
        in {
          name = cname; # servicename-role e.g. esphome-app
          inherit template;
          config = {
            inherit image cmd entrypoint ports dependsOn autoStart user;
            log-driver = "journald";
            volumes = [ "/etc/localtime:/etc/localtime:ro" ] ++ map mount mounts ++ extraMounts; # mount is function which runs on each item in mounts
            environment = {
              "TZ" = vars.timeZone;
              "PUID" = toString vars.containerUser.uid; # for linuxserver images
              "PGID" = toString vars.containerUser.gid; # for linuxserver images
            } // environment;
            environmentFiles =
              lib.optionals (secrets != {}) [ config.sops.templates."${cname}.env".path ];
            extraOptions =
              lib.optionals noNewPrivileges [ "--security-opt=no-new-privileges:true" ]
              ++ [ "--log-opt=max-size=10m" "--log-opt=max-file=3" ]
              ++ extraOptions
              ++ lib.concatMap (f: f.extraOptions or []) hw;
            devices = devices ++ lib.concatMap (f: f.devices) hw;
            capabilities = { "NET_RAW" = false; } // capabilities;
            networks = [ "${name}-net:ip=${mkIp serviceId containerId},ip6=${mkIp6 serviceId containerId}" ] ++ extraNetworks;
            labels = {
              "glance.name" = glanceName;
              "glance.icon" = "di:${name}";
              "glance.hide" = "true";
              "requires.internet" = lib.boolToString internet; # evaluated by sensei to allow outbound connections
              "address.ipv4" = mkIp serviceId containerId;
              "address.ipv6" = mkIp6 serviceId containerId;
            } // webLabels // labels; # merge, sjallow, e.g. glance.hide = "false" will override it
          };
        };

      # postgres preset
      db = { user, 
             database,
             image ? "postgres:16.15", 
             id ? 3,
             mounts ? [ "/data/postgres" ], 
             environment ? {}, 
             extraOptions ? [], 
             internet ? false
            }: container {
        inherit image id mounts internet;
        environment = ({
          POSTGRES_USER = user;
          POSTGRES_DB = database;
          PGDATA = "/data/postgres";
        } // environment);
        secrets = { POSTGRES_PASSWORD = "apps/${name}/db/password"; };
        extraOptions = [
          "--shm-size=256m"
          "--stop-timeout=60"
          "--health-cmd=pg_isready -U ${user} -d ${database}"
          "--health-interval=1m"
          "--health-timeout=5s"
          "--health-retries=5"
          "--health-start-period=10s"
        ] ++ extraOptions;
      };

      # module body for service.nix: containers + their env templates + network
      build = containers:
        let records = lib.mapAttrs (role: mk: mk role) containers;
        in {
          virtualisation.oci-containers.containers = lib.mapAttrs' (_: r: lib.nameValuePair r.name r.config) records;
          sops.templates = lib.filterAttrs (_: t: t != null)
            (lib.mapAttrs' (_: r: lib.nameValuePair "${r.name}.env" r.template) records);
          systemd.services = mkNetwork;
        };

    in {
      # helper for container name
      containerName = role: "${name}-${role}";
      inherit container db build;
    };

in {
  inherit service;
}
