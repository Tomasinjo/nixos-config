# This addresses problem with high idle GPU power even if the GPU is in P8 state and without any processes
# Conditions: P8 state, no processes, power above 24W (typically 35W)
# Action: Put card to suspended state and restore it after two seconds
# Run checks every 15 minutes
# Power is decreased to 14-15W


{ config, lib, pkgs, ... }:

let
  cfg = config.modules.hardware.nvidia.idlePowerReset;

  idlePowerResetScript = pkgs.writeShellApplication {
    name = "nvidia-idle-power-reset";
    runtimeInputs = [ config.hardware.nvidia.package pkgs.coreutils pkgs.bc ];
    text = ''
      POWER=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits)
      PSTATE=$(nvidia-smi --query-gpu=pstate --format=csv,noheader,nounits)
      PROCESSES=$(nvidia-smi --query-compute-apps=pid,process_name,used_gpu_memory --format=csv,noheader)

      if [ "$PSTATE" = "P8" ] && [ -z "$PROCESSES" ] && [ "$(echo "$POWER > 24" | bc)" -eq 1 ]; then
        echo "Conditions met: P8, no processes, power over threshold. Resetting GPU power..."
        echo suspend > /proc/driver/nvidia/suspend
        sleep 2
        echo resume > /proc/driver/nvidia/suspend
        echo "GPU power reset complete."
      fi
    '';
  };
in {
    environment.systemPackages = [ idlePowerResetScript ];

    systemd.services.nvidia-idle-power-reset = {
      description = "Reset NVIDIA GPU power when idle with high power draw";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = "${idlePowerResetScript}/bin/nvidia-idle-power-reset";
        StandardOutput = "journal+console";
        StandardError = "journal+console";
      };
    };

    systemd.timers.nvidia-idle-power-reset = {
      description = "Timer for NVIDIA GPU idle power reset";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/15";  # Every 15 minutes
        Persistent = true;
      };
    };
}
