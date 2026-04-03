{ config, pkgs, inputs, vars, ... }:

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
          exec ${pkgs.chromium}/bin/chromium --kiosk --start-fullscreen --noerrdialogs --no-first-run --check-for-update-interval=31536000 --app="https://ha.${vars.net.domain}"
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


  users.users.${vars.username}.extraGroups = [ 
    "video"
    "input"
  ];

  # Required for Wayland/Firefox to work correctly with system d-bus
  programs.dconf.enable = true;
}
