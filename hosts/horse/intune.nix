{ pkgs, ... }:

{
  # 1. Enable the background service
  services.intune.enable = true;

  # 2. Install the necessary packages
  environment.systemPackages = [
    pkgs.intune-portal            # The actual GUI application
    pkgs.microsoft-identity-broker # The login handler
  ];

  # 3. Apply the version override
  nixpkgs.overlays = [
    (final: prev: {
      microsoft-identity-broker = prev.microsoft-identity-broker.overrideAttrs (oldAttrs: {
        src = pkgs.fetchurl {
          url = "https://packages.microsoft.com/ubuntu/22.04/prod/pool/main/m/microsoft-identity-broker/microsoft-identity-broker_2.0.1_amd64.deb";
          sha256 = "bff171b5dbd16941d8aaf152909219ca270875ccb143c94fa58e6b6fdb269ea0";
        };
      });
    })
  ];
}
