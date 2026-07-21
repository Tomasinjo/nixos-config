{ config, lib, pkgs, vars, ... }:

let
  internal_ipv4 = [ "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16" ];
in
{
  networking.wg-quick.interfaces.protonvpn = {
    table = "off";
    address = [ "10.2.0.2/32" "2a07:b944::2:2/128" ];
    dns = [ "10.2.0.1" "2a07:b944::2:1" ];
    privateKey = vars.wg.protonvpn.privatekey;
    peers = [{
      publicKey = "vH2i8RY1qc66XfqwrixBpvH4K9GYJatkugJj0GHgoUQ=";
      allowedIPs = [ "0.0.0.0/0" "::/0" ];
      endpoint = "217.23.3.76:51820";
      persistentKeepalive = 25;
    }];
    autostart = true;
  };

  # Systemd service to add VPN routes after WireGuard handshake completes
  systemd.services.protonvpn-routes = {
    description = "Add ProtonVPN routes after handshake";
    after = [ "wg-quick-protonvpn.service" ];
    wants = [ "wg-quick-protonvpn.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "protonvpn-routes-start" ''
        # Wait for WireGuard handshake to complete
        timeout=30
        elapsed=0
        while true; do
          # Get the handshake timestamp (second field, should be > 0)
          handshake=$(${pkgs.wireguard-tools}/bin/wg show protonvpn latest-handshakes | ${pkgs.gawk}/bin/awk '{print $2}')
          if [ "$handshake" -gt 0 ] 2>/dev/null; then
            echo "WireGuard handshake completed at $handshake"
            break
          fi
          if [ $elapsed -ge $timeout ]; then
            echo "Timeout waiting for WireGuard handshake"
            exit 1
          fi
          sleep 1
          elapsed=$((elapsed + 1))
        done
        
        # Create custom routing table for VPN
        grep -q "200 vpn" /etc/iproute2/rt_tables || echo "200 vpn" >> /etc/iproute2/rt_tables
        
        # Route all traffic from VLAN 69 through VPN
        ${pkgs.iproute2}/bin/ip route add default dev protonvpn table vpn
        
        # Policy rules: traffic from VLAN 69 uses VPN table
        # First, exempt internal networks from VPN routing (higher priority = lower number)
        ${lib.concatMapStrings (net: ''
        ${pkgs.iproute2}/bin/ip rule add from ${vars.net.sensei.lab-vlan.ipv4.subnet}/${vars.net.sensei.lab-vlan.ipv4.mask} to ${net} lookup main prio 100
        '') internal_ipv4}
        # Then, send all other traffic from VLAN 69 to VPN
        ${pkgs.iproute2}/bin/ip rule add from ${vars.net.sensei.lab-vlan.ipv4.subnet}/${vars.net.sensei.lab-vlan.ipv4.mask} lookup vpn prio 200
      '';
      ExecStop = pkgs.writeShellScript "protonvpn-routes-stop" ''
        # Remove policy rules
        ${pkgs.iproute2}/bin/ip rule del from ${vars.net.sensei.lab-vlan.ipv4.subnet}/${vars.net.sensei.lab-vlan.ipv4.mask} lookup vpn prio 200 2>/dev/null || true
        ${lib.concatMapStrings (net: ''
        ${pkgs.iproute2}/bin/ip rule del from ${vars.net.sensei.lab-vlan.ipv4.subnet}/${vars.net.sensei.lab-vlan.ipv4.mask} to ${net} lookup main prio 100 2>/dev/null || true
        '') internal_ipv4}
        
        # Flush VPN routing table
        ${pkgs.iproute2}/bin/ip route flush table vpn 2>/dev/null || true
      '';
    };
  };
}
