# Migration Plan: Docker Compose to Nix OCI-Containers

## 1. Overview
This plan outlines the framework to migrate Docker Compose services inside the `apps/` directory to Nix-managed `virtualisation.oci-containers`. The migration is demonstrated using the `grocy` service as an example.

## 2. Shared Configuration Framework
In Docker Compose, common settings were defined in `apps/global-compose.yml` and extended. In Nix, we can achieve this using a helper module or function that provides default configurations for OCI containers.

We will create a module `modules/docker/oci-framework.nix` that defines common attributes (like the `base` and `web-base` definitions in `global-compose.yml`):
- `base`: sets user, security restrictions, restart policies.
- `web-base`: sets Traefik labels based on standard variables like `SERVICE_NAME`, `SERVICE_FQDN`, `SERVICE_PORT`.
- Network definitions: uses `extraOptions = [ "--network=traefik-net" ]` since OCI containers support docker CLI flags.

Services will use these helpers. For example, instead of `extends: { service: web-base-internal }`, the nix module for grocy will merge the default `web-base-internal` config with its specific config.

## 3. Environment Variables & Secrets
- **Build-time Variables**: Variables like `SERVICE_NAME` or `SERVICE_PORT` are used strictly to generate the configuration (e.g., Traefik labels). In Nix, these will simply be Nix `let` bindings or module arguments. They do not need to be passed into the container's environment.
- **Runtime Variables & Secrets**: Since `secrets.nix` is encrypted via `git-crypt`, we will define container-specific secrets and sensitive runtime variables within it. These variables will be imported and passed directly into the container's `environment` or written to a secure `.env` file via Nix tools/systemd if required to prevent them from landing in the world-readable nix-store unnecessarily. Since the user mentioned they are in `secrets.nix`, we will handle them safely within the nix deployment process.

## 4. Renovate Bot Support
Renovate bot supports standard image strings. However, if image strings are deeply nested in Nix, Renovate might miss them.
To ensure Renovate detects OCI container images in Nix:
1. We will format image strings cleanly: `image = "lscr.io/linuxserver/grocy:v4.5.0-ls316";`
2. We can add custom regex managers in `renovate.json` to match Nix files. For example:
   ```json
   {
     "customManagers": [
       {
         "customType": "regex",
         "fileMatch": ["\\.nix$"],
         "matchStrings": ["image\\s*=\\s*\"(?<depName>[^\"]+):(?<currentValue>[^\"]+)\";"],
         "datasourceTemplate": "docker"
       }
     ]
   }
   ```

## 5. Example Migration: Grocy
We will create `apps/grocy/default.nix` (or `apps/grocy/oci.nix`).
- It will define `virtualisation.oci-containers.containers.grocy-app`.
- It will merge settings from our `web-base-internal` Nix function.
- It will configure the volume mounts.

## Proposed Action Items (Next Steps in Implementation)
1. Create `modules/docker/oci-framework.nix` with helper functions for `base`, `web-base`, etc.
2. Update `renovate.json` with the regex manager for Nix files.
3. Create `apps/grocy/default.nix` using the framework.
4. Integrate `apps/grocy/default.nix` into the host's configuration.