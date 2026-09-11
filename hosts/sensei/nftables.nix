{
  config,
  lib,
  pkgs,
  vars,
  inputs,
  ...
}:

let
  aliases = {
    internal_ipv4 = "10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16";
  };

  # Generate list of IPs that are allowed to go to internet
  vlan30_allow_out_ips = lib.concatStringsSep ", " (
    map (m: m.ip) (
      builtins.filter (m: (m.allow_out or false) == true) (
        builtins.attrValues vars.net.sensei.iot-vlan.members
      )
    )
  );

  getContainers = import ../../helpers/get-containers.nix { inherit inputs lib; };
  serviceWithInternetAccess = getContainers {
      filter = name: c: (c.labels."requires.internet" or "false") == "true";
  };

  containers_allow_out_ip4 = lib.concatMapAttrsStringSep ", " (
    name: value: value.labels."address.ipv4"
  ) serviceWithInternetAccess;

  containers_allow_out_ip6 = lib.concatMapAttrsStringSep ", " (
    name: value: value.labels."address.ipv6"
  ) serviceWithInternetAccess;

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
                ct state { established, related } accept

                ct state invalid drop

                ip protocol icmp accept
                ip6 nexthdr icmpv6 accept

                iifname "lo" accept
                
                iifname "wg0" accept

                # DHCPv6 client
                iifname "ppp0" udp dport 546 accept 

                # Wireguard port on WAN
                iifname "ppp0" udp dport 8080 accept
      	        iifname "lo-wg" udp dport 8080 accept

                # Block everything else from WAN
                iifname "ppp0" drop

                # DHCPv4
                iifname {
                  ${vars.net.sensei.common-vlan.name},
                  ${vars.net.sensei.guest-vlan.name}, 
                  ${vars.net.sensei.iot-vlan.name},
                  ${vars.net.sensei.lab-vlan.name}
                } udp dport 67 accept

                ############ Guest ############
                iifname ${vars.net.sensei.guest-vlan.name} drop
                ip daddr ${vars.net.sensei.ipv4DNS} udp dport { 53, 123 } accept
                ip6 daddr ${vars.net.sensei.ipv6DNS} udp dport { 53, 123 } accept

                ############ IoT ############
                iifname ${vars.net.sensei.iot-vlan.name} drop

                ############ mgmt on LACP interface ############
                ether saddr ${vars.net.sensei.common-vlan.members.t14g6_wifi.mac} ip  daddr ${vars.net.sensei.mgmt-vlan.ipv4.gateway} tcp dport 22 accept
                ether saddr ${vars.net.sensei.common-vlan.members.t14g6.mac}      ip  daddr ${vars.net.sensei.mgmt-vlan.ipv4.gateway} tcp dport 22 accept
                ether saddr ${vars.net.sensei.common-vlan.members.t14g6_wifi.mac} ip6 daddr ${vars.net.sensei.mgmt-vlan.ipv6.gateway} tcp dport 22 accept
                ether saddr ${vars.net.sensei.common-vlan.members.t14g6.mac}      ip6 daddr ${vars.net.sensei.mgmt-vlan.ipv6.gateway} tcp dport 22 accept
                
                iifname "wg0" ip  daddr ${vars.net.sensei.mgmt-vlan.ipv4.gateway} tcp dport 22 accept
                iifname "wg0" ip6 daddr ${vars.net.sensei.mgmt-vlan.ipv6.gateway} tcp dport 22 accept


                ############ From server ############
                ip saddr ${vars.net.zenki.server-vlan.ipv4Address} ip daddr ${vars.net.sensei.mgmt-vlan.ipv4.gateway} udp dport 514 accept

              }

              chain forward {
                type filter hook forward priority 0; policy drop;

                ct state { established, related } accept
                
                ############ MGMT ############
                iifname "bond0" accept

                ############ Users ############
                ether saddr ${vars.net.sensei.common-vlan.members.t14g6_wifi.mac} accept
                ether saddr ${vars.net.sensei.common-vlan.members.t14g6.mac}      accept

                # To traefik
                iifname "${vars.net.sensei.common-vlan.name}" ip  daddr 10.0.1.2  accept
                iifname "${vars.net.sensei.common-vlan.name}" ip6 daddr ${vars.net.zenki.containers.prefix6}:1001::2 accept
                
                # Speakers to MA
                iifname "${vars.net.sensei.common-vlan.name}" ip saddr { 192.168.10.152, 192.168.10.154 } ip daddr 10.0.39.2 tcp dport 8097 accept 

                iifname "${vars.net.sensei.common-vlan.name}" ip  daddr ${vars.net.zenki.containers.subnet}  drop
                iifname "${vars.net.sensei.common-vlan.name}" ip6 daddr ${vars.net.zenki.containers.subnet6} drop

                iifname "${vars.net.sensei.common-vlan.name}" accept


                ############ Guest ############
                iifname "${vars.net.sensei.guest-vlan.name}" ip daddr != { ${aliases.internal_ipv4} } accept


                ############ IoT ############

                # shelly 3EM to HA
                iifname "${vars.net.sensei.iot-vlan.name}" ip saddr 192.168.30.77 ip daddr 10.0.22.2 tcp dport 5683 accept

                # exceptions that are allowed to access the internet
                ${
                  if vlan30_allow_out_ips != "" then
                    "iifname \"${vars.net.sensei.iot-vlan.name}\" ip saddr { ${vlan30_allow_out_ips} } ip daddr != { ${aliases.internal_ipv4} } accept"
                  else
                    ""
                }

                # mqtt clients to HA
                iifname "${vars.net.sensei.iot-vlan.name}" ip daddr 10.0.22.4 tcp dport 1883 accept


                ############ Server ############

                # allow any destination
                iifname "${vars.net.sensei.server-vlan.name}" ip  saddr ${vars.net.zenki.server-vlan.ipv4Address} accept
                iifname "${vars.net.sensei.server-vlan.name}" ip6 saddr ${vars.net.zenki.server-vlan.ipv6Address} accept

                # To traefik from internet
                iifname { "ppp0", "${vars.net.sensei.common-vlan.name}" } ip  daddr 10.0.1.2 tcp dport { 80, 443 } accept
                iifname { "ppp0", "${vars.net.sensei.common-vlan.name}" } ip6 daddr ${vars.net.zenki.containers.prefix6}:1001::2 tcp dport { 80, 443 } accept


                ############ Lab (VLAN 69) - routed via VPS ############
                #iifname "${vars.net.sensei.lab-vlan.name}" accept
                iifname "${vars.net.sensei.lab-vlan.name}" ip daddr ${vars.net.vps.ipv4Address} accept
                # use below for SCP file transfer via sensei 
      	        #iifname "${vars.net.sensei.lab-vlan.name}" ip daddr ${vars.net.sensei.mgmt-vlan.ipv4.subnet}/${vars.net.sensei.mgmt-vlan.ipv4.mask} accept


                ############ wireguard ############
                iifname "wg0" accept

                ############ Podman containers ############

                # port forwarded, torrents
                iifname "ppp0" ip daddr 10.0.4.2 tcp dport 51413 accept
                iifname "ppp0" ip daddr 10.0.4.2 udp dport 51413 accept
                iifname "ppp0" ip6 daddr ${vars.net.zenki.containers.prefix6}:1004::2 tcp dport 51413 accept
                iifname "ppp0" ip6 daddr ${vars.net.zenki.containers.prefix6}:1004::2 udp dport 51413 accept

                # music assistant to speakers
                iifname "${vars.net.sensei.server-vlan.name}" ip saddr 10.0.39.2 ip daddr { 192.168.10.152, 192.168.10.154 } accept

                # home assistant everywhere
                iifname ${vars.net.sensei.server-vlan.name} ip saddr 10.0.22.2 accept
                iifname ${vars.net.sensei.server-vlan.name} ip6 saddr ${vars.net.zenki.containers.prefix6}:1022::2 accept

                # esphome to IoT
                iifname ${vars.net.sensei.server-vlan.name} ip saddr 10.0.21.2 oifname "${vars.net.sensei.iot-vlan.name}" accept

                # frigate to cameras
                iifname ${vars.net.sensei.server-vlan.name} ip saddr 10.0.16.2 ip daddr { 192.168.30.78, 192.168.30.80, 192.168.30.85, 192.168.30.56, 192.168.30.57, 192.168.30.58, 192.168.30.158 } accept
                
                # allow outbound, based on podman labels
                ip  saddr { ${containers_allow_out_ip4} } oifname "ppp0" accept
                ip6 saddr { ${containers_allow_out_ip6} } oifname "ppp0" accept
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
