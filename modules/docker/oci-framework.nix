{ lib, vars }:

let
  # The base configuration every container should have
  common = {
    user = "1111:1111";
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
    ];
    extraOptions = [
      "--security-opt=no-new-privileges:true"
      "--cap-drop=NET_RAW"
      "--log-driver=json-file"
      "--log-opt=max-size=10m"
      "--log-opt=max-file=3"
    ];
  };

  # Helper to merge a base config with service-specific overrides.
  # It safely combines lists (volumes, extraOptions, dependsOn, ports) 
  # and merges attribute sets (environment, labels).
  # It also supports explicitly removing items from the base lists via `removeExtraOptions`, etc.
  merge = base: overrides: 
    let
      baseVolumes = lib.subtractLists (overrides.removeVolumes or []) (base.volumes or []);
      baseExtraOpts = lib.subtractLists (overrides.removeExtraOptions or []) (base.extraOptions or []);
      basePorts = lib.subtractLists (overrides.removePorts or []) (base.ports or []);
      baseDependsOn = lib.subtractLists (overrides.removeDependsOn or []) (base.dependsOn or []);
      
      merged = base // overrides // {
        volumes = baseVolumes ++ (overrides.volumes or []);
        extraOptions = baseExtraOpts ++ (overrides.extraOptions or []);
        ports = basePorts ++ (overrides.ports or []);
        dependsOn = baseDependsOn ++ (overrides.dependsOn or []);
        environment = (base.environment or {}) // (overrides.environment or {});
        labels = (base.labels or {}) // (overrides.labels or {});
      };
    in builtins.removeAttrs merged ["removeVolumes" "removeExtraOptions" "removePorts" "removeDependsOn"];

  # Generates the traefik labels based on service details
  traefik = { serviceName, servicePort, internal ? true }: {
    extraOptions = [
      "--network=traefik-net"
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.${serviceName}.rule=Host(`${serviceName}.${vars.networking.domain}`)"
      "--label=traefik.http.routers.${serviceName}.entrypoints=https,http"
      "--label=traefik.http.routers.${serviceName}.tls=true"
      "--label=traefik.http.services.${serviceName}.loadbalancer.server.port=${toString servicePort}"
    ] ++ (if internal 
      then [ "--label=traefik.http.routers.${serviceName}.middlewares=internal-whitelist@file" ]
      else [ 
        "--label=traefik.http.routers.${serviceName}.tls.certresolver=fikus_resolver"
        "--label=traefik.http.routers.${serviceName}.middlewares=dynamic-whitelist@file"
      ]);
  };

  # Pre-combined templates for convenience
  templates = {
    web-internal = { serviceName, servicePort }: 
      merge common (traefik { inherit serviceName servicePort; internal = true; });

    web-exposed = { serviceName, servicePort }: 
      merge common (traefik { inherit serviceName servicePort; internal = false; });
  };

in {
  inherit common traefik templates merge;
}