{ config, lib, vars, ... }:

let
  cfg = config.modules.vector;

  # When podman container logs are collected via docker.sock, journald events
  # are deduplicated through filter_podman_from_journal before reaching the sink.
  journaldSinkInputs = if cfg.enablePodman then [ "filter_podman_from_journal" ] else [ "journald" ];
in
{
  options.modules.vector = {
    enable = lib.mkEnableOption "log shipping to VictoriaLogs (journald, zsh history, optional podman/files)";

    enablePodman = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Also collect podman container logs via docker.sock and filter their duplicates out of journald.";
    };

    extraFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional log files to tail and ship.";
    };

    victorialogsUri = lib.mkOption {
      type = lib.types.str;
      default = "http://10.0.37.2:9428/insert/jsonline?_stream_fields=host,source_type&_msg_field=message&_time_field=timestamp";
      description = "VictoriaLogs jsonline insert endpoint.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.vector = {
      isSystemUser = true;
      group = "vector";
      extraGroups =
        [
          "adm" # for journald
          "users" # for reading extra files under /home/tom
        ]
        ++ lib.optionals cfg.enablePodman [
          "podman" # To read /var/run/docker.sock
          vars.containerUser.name
        ];
    };
    users.groups.vector = { };

    services.vector = {
      enable = true;
      journaldAccess = true;
      settings = {
        sources = {
          journald.type = "journald";

          # configured in home-manager zsh; dir provisioned by modules/common.nix,
          # readable via the vector group
          zsh_history = {
            type = "file";
            include = [ "/var/log/zsh/history.jsonl" ];
          };

          vector_metrics.type = "internal_metrics";
        }
        // lib.optionalAttrs cfg.enablePodman {
          podman_containers = {
            type = "docker_logs"; # uses docker.sock, symlinked podman.sock
            multiline = {
              start_pattern = "^[^[:space:]]"; # New log starts with a non-space character (e.g., date/timestamp)
              condition_pattern = "^[[:space:]]"; # Continue merging if line starts with space/tab (e.g., stack trace lines)
              mode = "continue_through";
              timeout_ms = 1000; # Max time to wait for next line before flushing
            };
          };
        }
        // lib.optionalAttrs (cfg.extraFiles != [ ]) {
          local_files = {
            type = "file";
            include = cfg.extraFiles;
          };
        };

        transforms = {
          # the command becomes the log message
          remap_zsh_history = {
            type = "remap";
            inputs = [ "zsh_history" ];
            source = ''
              parsed = parse_json!(string!(.message))
              .timestamp = parse_timestamp(string!(parsed.timestamp), format: "%+") ?? now()
              .user = parsed.user
              .exit_code = parsed.exit_code
              .message = string!(parsed.command)
            '';
          };
        }
        // lib.optionalAttrs cfg.enablePodman {
          # Remove logs from journald that are already captured by the podman source (start with "podman-", but don't exclude podman-update since it is a backup script)
          filter_podman_from_journal = {
            type = "filter";
            inputs = [ "journald" ];
            condition = ''!starts_with(string(._SYSTEMD_UNIT) ?? "", "podman-") || starts_with(string(._SYSTEMD_UNIT) ?? "", "podman-update") || starts_with(string(._SYSTEMD_UNIT) ?? "", "podman-backup")'';
          };
        };

        sinks.victorialogs_host = {
          type = "http";
          inputs =
            journaldSinkInputs
            ++ lib.optional cfg.enablePodman "podman_containers"
            ++ lib.optional (cfg.extraFiles != [ ]) "local_files"
            ++ [ "remap_zsh_history" ];
          uri = cfg.victorialogsUri;
          compression = "gzip";
          encoding.codec = "json";
          framing.method = "newline_delimited";
          healthcheck.enabled = false;
        };
      };
    };
  };
}
