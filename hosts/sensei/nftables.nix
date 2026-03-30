{ config, lib, pkgs, vars, ... }:

let
  aliases = {    
    internal_ipv4 = "10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16";
  };

  # Generate comma-separated list of IPs that are allowed to go to internet
  vlan30_allow_out_ips = lib.concatStringsSep ", " (
    map (m: m.ip) (builtins.filter (m: (m.allow_out or false) == true) (builtins.attrValues vars.net.sensei.iot-vlan.members))
  );

in
{
  networking.nat.enable = false;
  networking.firewall.enable = false;

  networking.nftables = {
    enable = true;
    ruleset = ''
      table inet filter {
        chain input {
          type filter hook input priority 0; policy drop;

          # Allow related/established traffic
          ct state { established, related } accept
          ct state invalid drop

          ip protocol icmp accept
          ip6 nexthdr icmpv6 accept

          # Loopback
          iifname "lo" accept
          
          # Wireguard
          iifname "wg0" accept

          iifname "ppp0" udp dport 546 accept # DHCPv6 client

          # Wireguard port on WAN
          iifname "ppp0" udp dport 8080 accept

          # opt1 (LACP)
          ip daddr ${vars.net.sensei.mgmt-vlan.ipv4.gateway} tcp dport 22 accept
          ip daddr ${vars.net.sensei.mgmt-vlan.ipv6.gateway} tcp dport 22 accept

          # opt2 (VLAN10)
          iifname "${vars.net.sensei.common-vlan.name}" udp dport 67 accept  # DHCPv4

          # opt3 (Guest)
          iifname "${vars.net.sensei.guest-vlan.name}" udp dport 67 accept  # DHCPv4

          # opt4 (IoT) rules
          iifname "${vars.net.sensei.iot-vlan.name}" udp dport 67 accept  # DHCPv4

          # opt5 (lo-dns)
          ip daddr ${vars.net.sensei.ipv4DNS} udp dport { 53, 123 } accept
          ip daddr ${vars.net.sensei.ipv4DNS} tcp dport 53 accept
          ip6 daddr ${vars.net.sensei.ipv6DNS} udp dport { 53, 123 } accept
          ip6 daddr ${vars.net.sensei.ipv6DNS} tcp dport 53 accept

          # Block everything else from WAN
          iifname "ppp0" drop
        }

        chain forward {
          type filter hook forward priority 0; policy drop;

          ct state { established, related } accept
          
          # To traefik from internet
          iifname { "ppp0", "${vars.net.sensei.common-vlan.name}" } ip daddr ${vars.net.zenki.common-vlan.mac-vlan.traefik.ipv4Address} tcp dport { 80, 443 } accept
          iifname { "ppp0", "${vars.net.sensei.common-vlan.name}" } ip6 daddr ${vars.net.zenki.common-vlan.mac-vlan.traefik.ipv6Address} tcp dport { 80, 443 } accept

          # To torrent from internet
          iifname "ppp0" ip daddr ${vars.net.zenki.common-vlan.ipv4Address} tcp dport 51413 accept
          iifname "ppp0" ip daddr ${vars.net.zenki.common-vlan.ipv4Address} udp dport 51413 accept
          
          # opt1 to anywhere
          iifname "bond0" accept

          # Users
          iifname "${vars.net.sensei.common-vlan.name}" accept

          # Guest
          iifname "${vars.net.sensei.guest-vlan.name}" ip daddr != { ${aliases.internal_ipv4} } accept

          # IoT
          iifname "${vars.net.sensei.iot-vlan.name}" ip saddr 192.168.30.77 ip daddr != { ${aliases.internal_ipv4} } accept
          ${if vlan30_allow_out_ips != "" then "iifname \"${vars.net.sensei.iot-vlan.name}\" ip saddr { ${vlan30_allow_out_ips} } ip daddr != { ${aliases.internal_ipv4} } accept" else ""}
          iifname "${vars.net.sensei.iot-vlan.name}" ip daddr ${vars.net.zenki.common-vlan.ipv4Address} tcp dport 1883 accept
          iifname "${vars.net.sensei.iot-vlan.name}" ip daddr ${vars.net.zenki.common-vlan.ipv4Address} accept

          # wireguard
          iifname "wg0" accept
        }

        chain output {
          type filter hook output priority 0; policy accept;
        }
      }

      table ip nat {
        chain prerouting {
          type nat hook prerouting priority dstnat; policy accept;

          # Port forwarding
          iifname { "ppp0", "${vars.net.sensei.common-vlan.name}" } ip daddr ${vars.net.sensei.ipv4_public} tcp dport 443 dnat to ${vars.net.zenki.common-vlan.mac-vlan.traefik.ipv4Address}:443
          iifname { "ppp0", "${vars.net.sensei.common-vlan.name}"} ip daddr ${vars.net.sensei.ipv4_public} tcp dport 80 dnat to ${vars.net.zenki.common-vlan.mac-vlan.traefik.ipv4Address}:80
          iifname "ppp0" tcp dport 51413 dnat to ${vars.net.zenki.common-vlan.ipv4Address}:51413
          iifname "ppp0" udp dport 51413 dnat to ${vars.net.zenki.common-vlan.ipv4Address}:51413
        }

        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;

          # Hairpin NAT for Traefik
          ip saddr ${vars.net.sensei.common-vlan.ipv4.subnet}/${vars.net.sensei.common-vlan.ipv4.mask} ip daddr ${vars.net.zenki.common-vlan.mac-vlan.traefik.ipv4Address} tcp dport { 80, 443 } snat to ${vars.net.sensei.common-vlan.ipv4.gateway}
          
          # Outbound NAT (Masquerade on WAN)
          oifname "ppp0" masquerade
        }
      }
      table inet mss-clamp {
          chain forward {
              type filter hook forward priority filter; policy accept;
              tcp flags syn tcp option maxseg size set 1380 oifname "ppp*"
              tcp flags syn tcp option maxseg size set 1380 iifname { 
		              "bond0",
		              "${vars.net.sensei.common-vlan.name}",
		              "${vars.net.sensei.guest-vlan.name}",
		              "${vars.net.sensei.iot-vlan.name}"
	            }
          }
      }

    '';
  };
}
