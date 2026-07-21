{ config, lib, pkgs, vars, ... }:

{
  # Install Proton VPN CLI and keyring utilities
  environment.systemPackages = with pkgs; [
    proton-vpn-cli
    pass
    python314Packages.keyring
    python314Packages.keyring.keyrings.alt
  ];

  # Use file-based keyring for headless operation
  environment.sessionVariables = {
    PYTHON_KEYRING_BACKEND = "keyrings.alt.file.PlaintextKeyring";
  };

  # Create directory for plaintext keyring (for headless operation)
  systemd.tmpfiles.rules = [
    "d /root/.local/share/python_keyring 0700 root root -"
  ];

  # Create systemd service for Proton VPN connection
  systemd.services.protonvpn-lab = {
    description = "Proton VPN for Lab VLAN (69)";
    after = [ "network-online.target" "systemd-networkd-wait-online.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.proton-vpn-cli}/bin/protonvpn connect";
      ExecStop = "${pkgs.proton-vpn-cli}/bin/protonvpn disconnect";
      Restart = "on-failure";
      RestartSec = "10s";
      # Run as root since VPN requires privileges
      User = "root";
      Group = "root";
      # Keep the service running
      RemainAfterExit = true;
    };
  };

  # Configure policy routing for VLAN 69 traffic through Proton VPN
  boot.kernel.sysctl = {
    "net.ipv4.conf.vlan69.rp_filter" = 2;
  };

  # Create custom routing table for VPN
  environment.etc."iproute2/rt_tables".text = ''
    200 vpn
  '';

  # Add network configuration for VPN routing
  systemd.network.networks."vpn-routing" = {
    matchConfig.Name = "vlan69";
    routingPolicyRules = [
      {
        From = "${vars.net.sensei.lab-vlan.ipv4.subnet}/${vars.net.sensei.lab-vlan.ipv4.mask}";
        Table = 200;
      }
    ];
  };

  # Note: The actual VPN interface name (e.g., proton0) will be determined by Proton VPN
  # Additional routing configuration may be needed after VPN connection is established
  # You may need to manually add routes like:
  # ip route add default via <vpn_gateway_ip> dev <vpn_interface> table 200
}
