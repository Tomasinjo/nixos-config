{ pkgs, ... }:

{
  systemd.services.set-cpu-efficiency = {
    description = "Set CPU Energy Performance Preference to balance_power";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'for f in /sys/devices/system/cpu/cpufreq/policy*/energy_performance_preference; do echo power > \"$f\"; done'";
    };
  };

  systemd.timers.set-cpu-efficiency = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "10min";          # Wait 10 minutes after boot
      Unit = "set-cpu-efficiency.service";
    };
  };
}
