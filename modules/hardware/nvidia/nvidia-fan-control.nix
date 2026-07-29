{ config, pkgs, lib, ... }:

let
  
  ##########################
  #  Custom GPU fan curve  #
  ##########################
  nvidia-fan-control = pkgs.buildGoModule rec {
    pname = "nvidia-fan-control";
    version = "2026-07-12"; # date of commit

    src = pkgs.fetchFromGitHub {
      owner = "Tomasinjo";
      repo = "nvidia-fan-control";
      rev = "main";
      sha256 = "sha256-biUy4EF8GxYMWAslyfURq48zSMbR7AUuY577GJIQq8A="; 
    };

    vendorHash = "sha256-2558crqhdYW9PY5Nd2hskjBTiotR9nj0ZjAHyM/l/vo="; 

    ldflags = [ "-extldflags=-Wl,-z,lazy" ];   # fix for error: undefined symbol: nvmlGpuInstanceGetComputeInstanceProfileInfoV
    buildInputs = [ config.hardware.nvidia.package ];
    
    nativeBuildInputs = [ pkgs.makeWrapper ];

    postInstall = ''
      wrapProgram $out/bin/nvidia-fan-control \
        --prefix LD_LIBRARY_PATH : "${config.hardware.nvidia.package}/lib"
    '';
  };

  fanConfigData = {
    time_to_update = 5;
    temperature_ranges = [
      { min_temperature = 0;  max_temperature = 35;  fan_speed = 0;   hysteresis = 3; }
      { min_temperature = 35; max_temperature = 45;  fan_speed = 30;  hysteresis = 3; }
      { min_temperature = 45; max_temperature = 65;  fan_speed = 85;  hysteresis = 0; }
      { min_temperature = 65; max_temperature = 400; fan_speed = 100; hysteresis = 0; }
    ];
  };

  # helper to use for both the file and the trigger
  configFile = pkgs.writeText "nvidia-fan-config.json" (builtins.toJSON fanConfigData);


  ######################################################
  # Script controls case fan, same speed as GPU fan    #
  ######################################################
  nvidia-fan-control-bash = pkgs.writeShellApplication {
    name = "nvidia-pwm4-control";
    runtimeInputs = [ pkgs.jq config.hardware.nvidia.package pkgs.coreutils ];
    text = ''
      # --- CONFIGURATION ---
      TARGET_NAME="nct6798"
      
      echo "Searching for hwmon device with name: $TARGET_NAME"
      
      HWMON_PATH=""
      for dev in /sys/class/hwmon/hwmon*; do
          if [[ -f "$dev/name" ]] && [[ "$(cat "$dev/name")" == "$TARGET_NAME" ]]; then
              HWMON_PATH="$dev"
              break
          fi
      done

      if [[ -z "$HWMON_PATH" ]]; then
          echo "Error: Could not find hwmon device for $TARGET_NAME"
          exit 1
      fi

      PWM_PATH="$HWMON_PATH/pwm4"
      ENABLE_PATH="$HWMON_PATH/pwm4_enable"
      
      echo "Found device at $HWMON_PATH"

      cleanup() {
          echo "Exiting: Restoring fan control to motherboard (fallback mode 5)..."
          echo 5 > "$ENABLE_PATH" || true
          exit
      }
      trap cleanup EXIT SIGINT SIGTERM
      
      # Enable manual control (1)
      echo 1 > "$ENABLE_PATH"

      # Initialize previous PWM value for change detection
      PREV_PWM_VALUE=-1

      while true; do
          FAN_VALUE=$(nvidia-smi --query-gpu=fan.speed --format=csv,noheader,nounits 2>/dev/null || echo "error")
          
          if [ -n "$FAN_VALUE" ] && [ "$FAN_VALUE" != "null" ]; then
              # Convert percentage (0-100) to PWM value (0-255)
              PWM_VALUE=$((FAN_VALUE * 255 / 100))
              
              # Only update and log if PWM value changed
              if [ "$PWM_VALUE" -ne "$PREV_PWM_VALUE" ]; then
                  #echo "Fan speed changed: $FAN_VALUE% (PWM: $PWM_VALUE)"
                  echo "$PWM_VALUE" > "$PWM_PATH"
                  PREV_PWM_VALUE=$PWM_VALUE
              fi
          fi

          sleep 5
      done
    '';
  };


in {
  environment.etc."nvidia-fan-control/config.json".source = configFile;
  
  # runs the program that implements custom GPU fan curve 
  systemd.services.nvidia-fan-control = {
    description = "NVIDIA Fan Control Service";
    after = [ "network.target" "nvidia-persistenced.service" ];
    wantedBy = [ "multi-user.target" ];
    restartTriggers = [ configFile ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${nvidia-fan-control}/bin/nvidia-fan-control";
      WorkingDirectory = "/etc/nvidia-fan-control";
      StandardOutput = "journal";
      StandardError = "journal";
      User = "root";
      Group = "root";
      Restart = "always";
    };
  };

  # runs the bash script that controls case fan according to config
  systemd.services.nvidia-pwm4-control = {
    description = "NVIDIA GPU PWM4 Fan Control (Bash)";
    after = [ "network.target" "nvidia-persistenced.service" ];
    wantedBy = [ "multi-user.target" ];
    restartTriggers = [ configFile ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${nvidia-fan-control-bash}/bin/nvidia-pwm4-control";
      StandardOutput = "journal";
      StandardError = "journal";
      User = "root";
      Group = "root";
      Restart = "always";
    };
  };
}
