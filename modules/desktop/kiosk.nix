{ pkgs, vars, ... }:

{
  imports = [
    ./sound.nix
    ./fonts.nix
  ];

  environment.systemPackages = [ 
    pkgs.sway 
    pkgs.chromium
    (pkgs.writeShellScriptBin "kiosk-screen" ''
      ACTION=$1

      # Validate arguments
      if [[ ! "$ACTION" =~ ^(on|off|status)$ ]]; then
        echo "Usage: kiosk-screen [on|off|status]"
        exit 1
      fi

      KIOSK_UID=$(id -u ${vars.username})
      export SWAYSOCK=$(ls /run/user/$KIOSK_UID/sway-ipc.*.sock 2>/dev/null | head -n 1)
      
      if [ -z "$SWAYSOCK" ]; then
        echo "Could not find Sway socket. Is Sway running?"
        exit 1
      fi

      # Helper function to execute swaymsg as the correct user
      run_swaymsg() {
        if [ "$EUID" -eq 0 ]; then
          sudo -u ${vars.username} SWAYSOCK=$SWAYSOCK ${pkgs.sway}/bin/swaymsg "$@"
        else
          ${pkgs.sway}/bin/swaymsg "$@"
        fi
      }

      # Handle commands
      if [ "$ACTION" == "on" ]; then
        run_swaymsg "output * dpms on" > /dev/null
        
      elif [ "$ACTION" == "off" ]; then
        run_swaymsg "output * dpms off" > /dev/null
        
      elif [ "$ACTION" == "status" ]; then
        # Parse the JSON response for the first output's DPMS status using jq
        DPMS_STATE=$(run_swaymsg -t get_outputs | ${pkgs.jq}/bin/jq -r '.[0].dpms')
        
        if [ "$DPMS_STATE" == "true" ]; then
          echo "on"
        elif [ "$DPMS_STATE" == "false" ]; then
          echo "off"
        else
          echo "unknown"
        fi
      fi
    '')
  ];


  services.xserver.enable = false;  # Disable Xorg

  programs.chromium = {
    enable = true;
    extraOpts = {
      "AutoSelectCertificateForUrls" = [
        ''{"pattern":"https://ha.${vars.net.domain}","filter":{}}'' # for mtls, prevents cert   selection popup every time.
      ];
      "ExitTypeRestorePolicy" = "none";
      "PasswordManagerEnabled" = false;
      "AutofillAddressEnabled" = false;
      "AutofillCreditCardEnabled" = false;
      "AutoplayAllowed" = true;
      "TranslateEnabled" = false;
      "BrowserGuestModeEnabled" = false;
      "BrowserSignin" = 0; # 0 = Disable sign-in
      "DefaultNotificationsSetting" = 1; 
      "DefaultPopupsSetting" = 2;
      "BackgroundModeEnabled" = true;
      "DefaultSearchProviderEnabled" = false;
      "FullscreenAllowed" = true;
      "TouchVirtualKeyboardEnabled" = 1; # 1 = Always enabled
      "KioskMode" = true;
    };
  };

  programs.sway.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        user = vars.username;
        command = pkgs.writeShellScript "kiosk-script" ''
          export XDG_SESSION_TYPE=wayland
          export XDG_SESSION_DESKTOP=sway
          export XDG_CURRENT_DESKTOP=sway
          
          cat <<EOF > /tmp/sway-kiosk-config
          output * bg #000000 solid_color
          exec ${pkgs.chromium}/bin/chromium \
            --remote-debugging-port=9222 \
            --kiosk \
            --start-fullscreen \
            --noerrdialogs \
            --no-first-run \
            --check-for-update-interval=31536000 \
            --app="https://ha.${vars.net.domain}"
          include /etc/sway/config.d/*
          EOF
          
          exec ${pkgs.sway}/bin/sway --config /tmp/sway-kiosk-config
        '';
      };
      default_session = {
        user = vars.username;
        command = "${pkgs.sway}/bin/sway"; 
      };
    };
  };


  systemd.services.kiosk-healthcheck = {
    description = "Check if Kiosk website is still alive";
    serviceConfig = {
      Type = "oneshot";
      User = "root"; 
      ExecStart = let
        script = pkgs.writeShellScript "kiosk-check.sh" ''
        export PATH=${pkgs.curl}/bin:${pkgs.jq}/bin:${pkgs.websocat}/bin:${pkgs.systemd}/bin:${pkgs.coreutils}/bin:$PATH
        
        DATA=$(curl -s --max-time 5 http://localhost:9222/json)
        
        # Extract the WebSocket URL for the specific page
        WS_URL=$(echo "$DATA" | jq -r '.[] | select(.type=="page" and (.title | contains("Home Assistant")) and (.url | contains("https://ha.${vars.net.domain}"))) | .webSocketDebuggerUrl' | head -n 1)

        # Check if URL was found
        if [ -z "$WS_URL" ] || [ "$WS_URL" == "null" ]; then
          echo "Kiosk page not found in tab list. Rebooting..."
          reboot
          exit 1
        fi

        # Try to run a simple JS command via WebSocket
        # If website crashed, it hangs here
        PROBE_COMMAND='{"id": 1, "method": "Runtime.evaluate", "params": {"expression": "1+1"}}'
        
        # Detects timeout
        RESPONSE=$(echo "$PROBE_COMMAND" | timeout 5s websocat -n1 -t --oneshot "$WS_URL" 2>/dev/null)

        # Validate the response
        # A healthy response looks like: {"id":1,"result":{"result":{"type":"number","value":2,"description":"2"}}}
        if [[ "$RESPONSE" == *"\"value\":2"* ]]; then
          echo "Kiosk is healthy."
        else
          echo "Kiosk is unresponsive or crashed. Rebooting..."
          reboot
        fi
      '';
    in "${script}";
    };
  };
  
  systemd.timers.kiosk-healthcheck = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "5m";
      Unit = "kiosk-healthcheck.service";
    };
  };

  users.users.${vars.username}.extraGroups = [ 
    "video"
    "input"
  ];

  # Required for Wayland/Firefox to work correctly with system d-bus
  programs.dconf.enable = true;
}
