# command-history.nix — record interactive shell commands to journald
# so they ship to VictoriaLogs (via the vector journald source on zenki)
# and the log-watch agent can correlate error spikes with user actions.
#
# What lands in journald (SYSLOG_IDENTIFIER="command-history"):
#   {"user":"tom","pwd":"/etc/nixos","cmd":"podman restart immich",
#    "exit":0,"duration_ms":1842,"tail":""}
#   - exit != 0  -> logged at PRIORITY=3 (err)  => shows up in error sweeps
#   - exit == 0  -> logged at PRIORITY=6 (info)
#   - "tail"     -> last ~2KB of stderr, ONLY for wrapped commands that failed
#
# Secrets: args matching token/password/secret/api[-_]key patterns are
# redacted before logging (see the sed in zsh_log_command).
{ config, pkgs, lib, vars, ... }:

let
  cfg = config.services.command-history;

  # Commands whose stderr is captured on failure. Extend per-host:
  #   services.command-history.wrapCommands = [ "nixos-rebuild" "deploy" ];
  defaultWrapped = [ "nixos-rebuild" ];

  # Build a zsh function per wrapped command that tees stderr to a temp
  # file, runs the real command, and injects the tail into the JSON log.
  mkWrapper = cmd: ''
    ${cmd}() {
      local __ch_errfile
      __ch_errfile=$(mktemp /tmp/cmdhist.XXXXXX)
      command ${cmd} "$@" 2> >(tee /dev/stderr > "$__ch_errfile")
      local __ch_rc=$?
      __CH_TAIL=$(tail -c 2048 "$__ch_errfile" 2>/dev/null | tr '\n' ' ' | tr -d '\000')
      rm -f "$__ch_errfile"
      return $__ch_rc
    }
  '';
  wrappers = lib.concatStrings (map mkWrapper cfg.wrapCommands);
in
{
  options.services.command-history = {
    enable = lib.mkEnableOption "interactive command history logging to journald";
    wrapCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = defaultWrapped;
      description = "Commands to wrap for stderr capture on failure (output tail lands in the log entry).";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zsh.enable = true;
    programs.zsh.interactiveShellInit = ''
      # --- command-history logging (managed by NixOS) ---
      __CH_START=0
      __CH_CMD=""
      __CH_TAIL=""

      __ch_json_escape() {
        # escape backslashes, double quotes, and control chars for JSON
        sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g' "$@"
      }

      __ch_redact() {
        # mask values after token/password/secret/api-key style flags and assignments
        sed -E \
          -e 's/((token|password|passwd|secret|api[-_]?key|authorization)[[:space:]]*[=:][[:space:]]*)[^[:space:]"'"'"']+/\1<REDACTED>/Ig' \
          -e 's/(--(token|password|secret|api[-_]?key)[[:space:]]+)[^[:space:]]+/\1<REDACTED>/Ig'
      }

      zsh_log_command() {
        local rc=$1
        local dur=$(( ( $(date +%s%N) - __CH_START ) / 1000000 ))
        local cmd
        cmd=$(printf '%s' "$__CH_CMD" | __ch_redact | __ch_json_escape)
        local tail_escaped
        tail_escaped=$(printf '%s' "$__CH_TAIL" | __ch_json_escape)
        local prio=6
        [ "$rc" -ne 0 ] && prio=3
        local pwd_escaped
        pwd_escaped=$(printf '%s' "$PWD" | __ch_json_escape)
        printf '{"user":"%s","pwd":"%s","cmd":"%s","exit":%d,"duration_ms":%d,"tail":"%s"}' \
          "${USER:-$(id -un)}" "$pwd_escaped" "$cmd" "$rc" "$dur" "$tail_escaped" \
          | systemd-cat -t command-history -p "$prio"
        __CH_TAIL=""
      }

      autoload -Uz add-zsh-hook
      __ch_preexec() {
        __CH_START=$(date +%s%N)
        __CH_CMD="$1"
      }
      __ch_precmd() {
        # only log if a command ran since the last prompt
        if [ -n "$__CH_CMD" ]; then
          zsh_log_command "$?"
          __CH_CMD=""
        fi
      }
      add-zsh-hook preexec __ch_preexec
      add-zsh-hook precmd __ch_precmd

      ${wrappers}
      # --- end command-history ---
    '';
  };
}
