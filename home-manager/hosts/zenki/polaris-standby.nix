# Polaris standby: the RTX 3090 is shared with ollama, whose local models need
# the whole card when not gaming. polaris (host + standby gamescope) reserves
# ~430MB even while idle, which makes big model loads fail. These units stop
# polaris once no Moonlight client has been connected for a few minutes, and
# wake it again when a client polls the host status port (TCP 47984 — what
# Moonlight uses on saved hosts).
{ config, pkgs, ... }:

let
  # how long to stay up after the last client disconnects; long enough to
  # cover quitting one game and launching another
  graceSeconds = 300;

  runtimeDir = "''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/polaris-standby";

  standbyManager = pkgs.writeShellScript "polaris-standby-manager" ''
    dir="${runtimeDir}"
    stamp="$dir/last-client"
    ${pkgs.coreutils}/bin/mkdir -p "$dir"
    now=$(${pkgs.coreutils}/bin/date +%s)

    if systemctl --user is-active --quiet polaris.service; then
      if ${pkgs.iproute2}/bin/ss -Htn state established '( sport = :47989 )' | ${pkgs.gnugrep}/bin/grep -q .; then
        # a moonlight client is connected (active stream or game list)
        ${pkgs.coreutils}/bin/touch "$stamp"
      elif [ ! -f "$stamp" ]; then
        # first sighting, start the grace clock
        ${pkgs.coreutils}/bin/touch "$stamp"
      elif [ $(( now - $(${pkgs.coreutils}/bin/stat -c %Y "$stamp") )) -lt ${toString graceSeconds} ]; then
        # inside the grace window after the last client left
        :
      else
        systemctl --user stop polaris.service polaris-gamescope-idle.service
        ${pkgs.coreutils}/bin/rm -f "$stamp"
      fi
    fi

    if ! systemctl --user is-active --quiet polaris.service; then
      # polaris down: hold the status port so a client poll can wake it
      systemctl --user start polaris-wake.socket 2>/dev/null || true
    fi
  '';

  wakePolaris = pkgs.writeShellScript "polaris-wake" ''
    dir="${runtimeDir}"
    ${pkgs.coreutils}/bin/mkdir -p "$dir"
    ${pkgs.coreutils}/bin/touch "$dir/last-client"
    systemctl --user start polaris.service
    systemctl --user stop polaris-wake.socket
  '';
in
{
  systemd.user.services.polaris-standby = {
    Unit.Description = "Stop polaris when idle to free GPU VRAM";
    Service = {
      Type = "oneshot";
      ExecStart = standbyManager;
    };
  };

  systemd.user.timers.polaris-standby = {
    Unit.Description = "Check polaris idleness every minute";
    Install.WantedBy = [ "timers.target" ];
    Timer = {
      OnBootSec = "2min";
      OnUnitActiveSec = "1min";
    };
  };

  systemd.user.sockets.polaris-wake = {
    Unit.Description = "Hold Moonlight status port while polaris is stopped";
    Socket.ListenStream = "47984";
  };

  systemd.user.services.polaris-wake = {
    Unit.Description = "Wake polaris when a Moonlight client polls the host";
    Service = {
      Type = "oneshot";
      ExecStart = wakePolaris;
    };
  };
}
