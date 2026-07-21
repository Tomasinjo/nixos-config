{ config, lib, pkgs, vars, ... }:

{
  networking.wg-quick.interfaces.protonvpn = {
    table = "off";
    address = [ "10.2.0.2/32" "2a07:b944::2:2/128" ];
    #dns = [ "10.2.0.1" "2a07:b944::2:1" ];
    privateKey = vars.wg.protonvpn.privatekey;
    peers = [{
      publicKey = "vH2i8RY1qc66XfqwrixBpvH4K9GYJatkugJj0GHgoUQ=";
      allowedIPs = [ "0.0.0.0/0" "::/0" ];
      endpoint = "217.23.3.76:51820";
      persistentKeepalive = 25;
    }];
    autostart = true;

    # Create custom routing table and policy rules when VPN comes up
    postUp = ''
      # Create custom routing table for VPN
      grep -q "200 vpn" /etc/iproute2/rt_tables || echo "200 vpn" >> /etc/iproute2/rt_tables
      
      # Route all traffic from VLAN 69 through VPN
      ip route add default via 10.2.0.1 dev protonvpn table vpn
      ip -6 route add default via 2a07:b944::2:1 dev protonvpn table vpn
      
      # Policy rules: traffic from VLAN 69 uses VPN table
      ip rule add from ${vars.net.sensei.lab-vlan.ipv4.subnet}/${vars.net.sensei.lab-vlan.ipv4.mask} lookup vpn
      ip -6 rule add from ${vars.net.sensei.lab-vlan.ipv6.subnet}/${vars.net.sensei.lab-vlan.ipv6.mask} lookup vpn
    '';

    # Clean up routing table and policy rules when VPN goes down
    preDown = ''
      # Remove policy rules
      ip rule del from ${vars.net.sensei.lab-vlan.ipv4.subnet}/${vars.net.sensei.lab-vlan.ipv4.mask} lookup vpn 2>/dev/null || true
      ip -6 rule del from ${vars.net.sensei.lab-vlan.ipv6.subnet}/${vars.net.sensei.lab-vlan.ipv6.mask} lookup vpn 2>/dev/null || true
      
      # Flush VPN routing table
      ip route flush table vpn 2>/dev/null || true
      ip -6 route flush table vpn 2>/dev/null || true
    '';
  };
}
