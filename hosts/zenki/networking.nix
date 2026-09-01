{ config, pkgs, vars, ... }:

{
  networking.hostName = vars.net.zenki.hostname;
  networking.useNetworkd = true;
  networking.useDHCP = false;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv4.conf.default.forwarding" = 1;

    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.default.forwarding" = 1;
    
    "net.ipv6.conf.all.accept_ra" = 2;  # turn on router advertisment which get disabled when ipv6 forwarding is enabled
    "net.ipv6.conf.default.accept_ra" = 2;

    # Prevents kernel from dropping inter-bridge container traffic
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;

    # Prevents Podman's bridge netfilter from mangling routed packets
    "net.bridge.bridge-nf-call-iptables" = 0;
    "net.bridge.bridge-nf-call-ip6tables" = 0;
    "net.bridge.bridge-nf-call-arptables" = 0;
  };

  # Rename Interface based on MAC
  systemd.network.links."10-persistent-${vars.net.zenki.interface_name}" = {
    matchConfig.MACAddress = vars.net.zenki.interface_mac;
    linkConfig.Name = vars.net.zenki.interface_name;
  };

  # Configure Physical Interface (Trunk for VLANs)
  systemd.network.networks."10-${vars.net.zenki.interface_name}" = {
    matchConfig.Name = vars.net.zenki.interface_name;
    # Ensure link is up
    linkConfig.RequiredForOnline = "no";
    networkConfig.LinkLocalAddressing = "no";
    # Attach VLANs
    vlan = [
      vars.net.zenki.server-vlan.interface_name
      vars.net.zenki.lab-vlan.interface_name
    ];
  };

  # Configure VLAN 10 Interface
  systemd.network.netdevs."10-${vars.net.sensei.server-vlan.name}" = {
    netdevConfig = {
      Name = vars.net.zenki.server-vlan.interface_name;
      Kind = "vlan";
    };
    vlanConfig.Id = vars.net.sensei.server-vlan.id;
  };

  # IP Configuration for VLAN 10
  systemd.network.networks."20-${vars.net.sensei.server-vlan.name}" = {
    matchConfig.Name = vars.net.zenki.server-vlan.interface_name;
    address = [
      "${vars.net.zenki.server-vlan.ipv4Address}/${vars.net.sensei.server-vlan.ipv4.mask}"
      "${vars.net.zenki.server-vlan.ipv6Address}/${vars.net.sensei.server-vlan.ipv6.mask}"
    ];
    routes = [
      { Gateway = vars.net.sensei.server-vlan.ipv4.gateway; }
      { Gateway = vars.net.sensei.server-vlan.ipv6.gateway; }
    ];
    networkConfig = {
      IPv6AcceptRA = true;
    };
    # DNS settings
    networkConfig.DNS = [ 
      vars.net.sensei.ipv4DNS 
			vars.net.sensei.ipv6DNS 
    ];
  };

  # Configure VLAN 69 Interface (Lab) - Bridge port for virbr69
  systemd.network.netdevs."10-${vars.net.sensei.lab-vlan.name}" = {
    netdevConfig = {
      Name = vars.net.zenki.lab-vlan.interface_name;
      Kind = "vlan";
    };
    vlanConfig.Id = vars.net.sensei.lab-vlan.id;
  };

  # Bridge port configuration for VLAN 69 (no IP - handled by external DHCP on virbr69)
  systemd.network.networks."20-${vars.net.sensei.lab-vlan.name}" = {
    matchConfig.Name = vars.net.zenki.lab-vlan.interface_name;
    networkConfig.Bridge = "virbr69";
  };

  networking.firewall = {
      enable = false;
  };

  networking.nftables = {
    enable = true;
    ruleset = ''
      table inet netavark {
        chain POSTROUTING {
          type nat hook postrouting priority srcnat; policy accept;
          
          # override default podman rule to SNAT traffic between containers
          ip saddr ${vars.net.zenki.containers.subnet} ip daddr ${vars.net.zenki.containers.subnet} accept
          ip6 saddr ${vars.net.zenki.containers.subnet6} ip6 daddr ${vars.net.zenki.containers.subnet6} accept
        }
      }

      table ip nat {
        chain PREROUTING {
          type nat hook prerouting priority dstnat; policy accept;
        }
        chain POSTROUTING {
          type nat hook postrouting priority srcnat - 1; policy accept;
          
          # Disable SNAT so podman containers use their static ip for outbound traffic
          ip saddr ${vars.net.zenki.containers.subnet} accept
        }
      }

      table inet filter {
        chain input {
          type filter hook input priority filter; policy drop;

          iifname "lo" accept
          ct state { established, related } accept
          
          iifname "${vars.net.zenki.server-vlan.interface_name}" tcp dport 22 accept
          
          ip protocol icmp accept
          meta l4proto ipv6-icmp accept
          
          # Allow traffic from container bridges
          iifname "podman0" accept
          iifname "br-*" accept
        }

        chain forward {
          type filter hook forward priority filter; policy drop;
          ct state { established, related } accept
          meta l4proto ipv6-icmp accept

          # allow from everywhere to traefik
          ip daddr 10.0.1.2 tcp dport { 80, 443 } accept
          ip6 daddr ${vars.net.zenki.containers.prefix6}:1001::2 tcp dport { 80, 443 } accept

          # containers outbound and inbound and between each other
          ip saddr 192.168.0.0/16 ip daddr ${vars.net.zenki.containers.subnet} accept
          ip daddr ${vars.net.zenki.containers.subnet} ct state { established, related } accept
          ip saddr ${vars.net.zenki.containers.subnet} accept

          ip6 saddr ${vars.net.zenki.containers.subnet6} accept
          ip6 daddr ${vars.net.zenki.containers.subnet6} ct state { established, related } accept
          ip6 daddr ${vars.net.zenki.containers.subnet6} accept
        }
      }
      
      table ip raw {
        chain PREROUTING {
          type filter hook prerouting priority raw; policy accept;
          
          # Allow inbound & outbound supernet traffic bypass
          ip saddr ${vars.net.zenki.containers.subnet} accept
          ip daddr ${vars.net.zenki.containers.subnet} accept
        }
      }
    '';
  };
  
  users.users.${vars.username}.extraGroups = [ "networkmanager" ];
}
