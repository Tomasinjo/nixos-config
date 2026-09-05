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
	        iifname "lo-wg" udp dport 8080 accept

          # Block everything else from WAN
          iifname "ppp0" drop

          iifname {
            ${vars.net.sensei.common-vlan.name},
            ${vars.net.sensei.guest-vlan.name}, 
            ${vars.net.sensei.iot-vlan.name},
            ${vars.net.sensei.lab-vlan.name}
          } udp dport 67 accept  # DHCPv4


          # Guest
          iifname ${vars.net.sensei.guest-vlan.name} drop

          ip daddr ${vars.net.sensei.ipv4DNS} udp dport { 53, 123 } accept
          ip6 daddr ${vars.net.sensei.ipv6DNS} udp dport { 53, 123 } accept

          # IoT
          iifname ${vars.net.sensei.iot-vlan.name} drop

          # LACP
          ip daddr ${vars.net.sensei.mgmt-vlan.ipv4.gateway} tcp dport 22 accept
          ip6 daddr ${vars.net.sensei.mgmt-vlan.ipv6.gateway} tcp dport 22 accept
          ip daddr ${vars.net.sensei.mgmt-vlan.ipv4.gateway} udp dport 514 ip saddr ${vars.net.zenki.server-vlan.ipv4Address} accept

        }

        chain forward {
          type filter hook forward priority 0; policy drop;

          ct state { established, related } accept
          
          # opt1 to anywhere
          iifname "bond0" accept


          # Users
          iifname "${vars.net.sensei.common-vlan.name}" accept


          # Guest
          iifname "${vars.net.sensei.guest-vlan.name}" ip daddr != { ${aliases.internal_ipv4} } accept


          # IoT
          iifname "${vars.net.sensei.iot-vlan.name}" ip saddr 192.168.30.77 ip daddr 10.0.22.2 tcp dport 5683 accept  # shelly 3EM
          ${if vlan30_allow_out_ips != "" then "iifname \"${vars.net.sensei.iot-vlan.name}\" ip saddr { ${vlan30_allow_out_ips} } ip daddr != { ${aliases.internal_ipv4} } accept" else ""}
          iifname "${vars.net.sensei.iot-vlan.name}" ip daddr 10.0.22.4 tcp dport 1883 accept  # mqtt clients


          # Server
          iifname "${vars.net.sensei.server-vlan.name}" ip saddr ${vars.net.zenki.server-vlan.ipv4Address} accept
          iifname "${vars.net.sensei.server-vlan.name}" ip6 saddr ${vars.net.zenki.server-vlan.ipv6Address} accept
          ### To traefik from internet
          iifname { "ppp0", "${vars.net.sensei.common-vlan.name}" } ip daddr 10.0.1.2 tcp dport { 80, 443 } accept
          iifname { "ppp0", "${vars.net.sensei.common-vlan.name}" } ip6 daddr ${vars.net.zenki.containers.prefix6}:1001::2 tcp dport { 80, 443 } accept

          # Lab (VLAN 69) - routed via VPS
          #iifname "${vars.net.sensei.lab-vlan.name}" accept
          iifname "${vars.net.sensei.lab-vlan.name}" ip daddr ${vars.net.vps.ipv4Address} accept
          # use below for SCP file transfer via sensei 
	        #iifname "${vars.net.sensei.lab-vlan.name}" ip daddr ${vars.net.sensei.mgmt-vlan.ipv4.subnet}/${vars.net.sensei.mgmt-vlan.ipv4.mask} accept


          # wireguard
          iifname "wg0" accept


          # Docker containers
          # port forwarded, torrents
          iifname "ppp0" ip daddr 10.0.4.2 tcp dport 51413 accept
          iifname "ppp0" ip6 daddr ${vars.net.zenki.containers.prefix6}:1004::2 tcp dport 51413 accept
          iifname "ppp0" ip daddr 10.0.4.2 udp dport 51413 accept
          iifname "ppp0" ip6 daddr ${vars.net.zenki.containers.prefix6}:1004::2 udp dport 51413 accept
          # music assistant to speakers
          iifname "${vars.net.sensei.server-vlan.name}" ip saddr 10.0.39.2 ip daddr { 192.168.10.152, 192.168.10.154 } accept
          # home assistant everywhere
          iifname ${vars.net.sensei.server-vlan.name} ip saddr 10.0.22.2 accept
          iifname ${vars.net.sensei.server-vlan.name} ip6 saddr ${vars.net.zenki.containers.prefix6}:1022::2 accept
          # esphome to IoT
          iifname ${vars.net.sensei.server-vlan.name} ip saddr 10.0.21.2 oifname "${vars.net.sensei.iot-vlan.name}" accept
          # allow outbound
          ip saddr  10.0.1.2 oifname "ppp0" accept  # traefik out - cert renewal
          ip saddr  10.0.3.2 oifname "ppp0" accept  # prowlarr out - indexing
          ip saddr  10.0.4.2 oifname "ppp0" accept  # qbittrorent out
          ip saddr  10.0.5.2 oifname "ppp0" accept  # radarr out - imdb
          ip saddr  10.0.6.2 oifname "ppp0" accept  # sonarr out - imdb
          ip saddr 10.0.10.2 accept  # opecloud out - TODO make more specific. Calls identity provider on its own fqdn
          ip saddr 10.0.12.2 oifname "ppp0" accept  # degoog - search engines
          ip saddr 10.0.17.2 oifname "ppp0" accept  # glance - fetch news
          ip saddr 10.0.20.2 oifname "ppp0" accept  # appdaemon out - pip
          ip saddr 10.0.21.2 oifname "ppp0" accept  # esphome out - library downloads
          ip saddr 10.0.22.2 oifname "ppp0" accept  # hass out - hacs updates, cloud devices
          ip saddr 10.0.27.2 oifname "ppp0" accept  # ollama out - pulling models
          ip saddr 10.0.32.2 oifname "ppp0" accept  # teslamate out - tesla api
          ip saddr 10.0.33.2 oifname "ppp0" accept  # jellyfin out - imdb
          ip saddr 10.0.38.2 oifname "ppp0" accept  # nitter out - twitter
          ip saddr 10.0.39.2 oifname "ppp0" accept  # mass out - online radio
          ip saddr 10.0.40.2 oifname "ppp0" accept  # pinchflat - yt downloads

          ip6 saddr ${vars.net.zenki.containers.prefix6}:1001::2 oifname "ppp0" accept  # traefik out - cert renewal
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1003::2 oifname "ppp0" accept  # prowlarr out - indexing
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1004::2 oifname "ppp0" accept  # qbittrorent out
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1005::2 oifname "ppp0" accept  # radarr out - imdb
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1006::2 oifname "ppp0" accept  # sonarr out - imdb
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1010::2 accept  # opencloud out - cant login otherwise
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1012::2 oifname "ppp0" accept  # degoog - search engines
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1017::2 oifname "ppp0" accept  # glance - fetch news
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1020::2 oifname "ppp0" accept  # appdaemon out - pip
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1021::2 oifname "ppp0" accept  # esphome out - library downloads
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1022::2 oifname "ppp0" accept  # hass out - hacs updates, cloud devices
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1027::2 oifname "ppp0" accept  # ollama out - pulling models
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1032::2 oifname "ppp0" accept  # teslamate out - tesla api
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1033::2 oifname "ppp0" accept  # jellyfin out - imdb
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1038::2 oifname "ppp0" accept  # nitter out - twitter
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1039::2 oifname "ppp0" accept  # mass out - online radio
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1040::2 oifname "ppp0" accept  # pinchflat - yt downloads

          # ip saddr ${vars.net.zenki.containers.subnet} oifname "ppp0" accept
          # ip6 saddr ${vars.net.zenki.containers.subnet6} oifname "ppp0" accept
        }

        chain output {
          type filter hook output priority 0; policy accept;
        }
      }

      table ip nat {
        chain prerouting {
          type nat hook prerouting priority dstnat; policy accept;

          ip daddr 192.168.50.80 dnat to 193.77.156.2

          # Port forwarding
          iifname { "ppp0", "${vars.net.sensei.common-vlan.name}", wg0 } ip daddr ${vars.net.sensei.ipv4_public} tcp dport 443 dnat to 10.0.1.2:443
          iifname { "ppp0", "${vars.net.sensei.common-vlan.name}", "wg0"} ip daddr ${vars.net.sensei.ipv4_public} tcp dport 80 dnat to 10.0.1.2:80
          iifname "ppp0" tcp dport 51413 dnat to 10.0.4.2:51413
          iifname "ppp0" udp dport 51413 dnat to 10.0.4.2:51413
        }

        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;
          
          # Hairpin NAT for Traefik
          ip saddr ${vars.net.sensei.common-vlan.ipv4.subnet}/${vars.net.sensei.common-vlan.ipv4.mask} ip daddr 10.0.1.2 tcp dport { 80, 443 } snat to ${vars.net.sensei.common-vlan.ipv4.gateway}
          ip saddr ${vars.net.sensei.wireguard.ipv4.subnet}/${vars.net.sensei.wireguard.ipv4.mask} ip daddr 10.0.1.2 tcp dport { 80, 443 } snat to ${vars.net.sensei.wireguard.ipv4.gateway}
          
          # Outbound NAT (Masquerade on WAN)
          oifname "ppp0" masquerade

          # Outbound NAT for VPN (VLAN 69 traffic)
          ip saddr ${vars.net.sensei.lab-vlan.ipv4.subnet}/${vars.net.sensei.lab-vlan.ipv4.mask} oifname "protonvpn" masquerade
        }
      }
      table inet mss-clamp {
          chain forward {
              type filter hook forward priority filter; policy accept;
              tcp flags syn tcp option maxseg size set 1340 oifname "ppp*"
              tcp flags syn tcp option maxseg size set 1340 iifname {
                "bond0",
                "${vars.net.sensei.common-vlan.name}",
                "${vars.net.sensei.guest-vlan.name}",
                "${vars.net.sensei.iot-vlan.name}",
                "${vars.net.sensei.server-vlan.name}",
                "${vars.net.sensei.lab-vlan.name}"
              }
          }
      }

    '';
  };
}
