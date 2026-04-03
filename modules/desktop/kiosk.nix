{ config, pkgs, inputs, vars, ... }:

{
  imports = [
    ./sound.nix
    ./fonts.nix
  ];

  environment.systemPackages = [ pkgs.cage pkgs.chromium ];

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

  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        user = vars.username; 
        # wrap the command to ensure Wayland variables are set
        command = pkgs.writeShellScript "kiosk-script" ''
          sleep 10  # wait for network
          export XDG_SESSION_TYPE=wayland
          export XCURSOR_SIZE=0
          ${pkgs.cage}/bin/cage -- chromium --kiosk --start-fullscreen --noerrdialogs --no-first-run --check-for-update-interval=31536000 --app="https://ha.${vars.net.domain}"
        '';
      };
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd cage";
        user = "greeter";
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
