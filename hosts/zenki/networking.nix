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

  systemd.network.links."10-persistent-${vars.net.zenki.interface_name}" = {
    matchConfig.MACAddress = vars.net.zenki.interface_mac;
    linkConfig.Name = vars.net.zenki.interface_name;
  };

  systemd.network.networks."10-${vars.net.zenki.interface_name}" = {
    matchConfig.Name = vars.net.zenki.interface_name;
    linkConfig.RequiredForOnline = "no";
    networkConfig.LinkLocalAddressing = "no";
    vlan = [
      vars.net.zenki.server-vlan.interface_name
      vars.net.zenki.lab-vlan.interface_name
    ];
  };

  systemd.network.netdevs."10-${vars.net.sensei.server-vlan.name}" = {
    netdevConfig = {
      Name = vars.net.zenki.server-vlan.interface_name;
      Kind = "vlan";
    };
    vlanConfig.Id = vars.net.sensei.server-vlan.id;
  };

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

  systemd.network.netdevs."10-${vars.net.sensei.lab-vlan.name}" = {
    netdevConfig = {
      Name = vars.net.zenki.lab-vlan.interface_name;
      Kind = "vlan";
    };
    vlanConfig.Id = vars.net.sensei.lab-vlan.id;
  };

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

          iifname "br-*" udp dport 53 accept
          iifname "br-*" tcp dport 53 accept

          
          # Prevent container access to host IP
          iifname "podman0" drop
          iifname "br-*" drop
        }

        chain forward {
          type filter hook forward priority filter; policy drop;

          ct state { established, related } accept
          meta l4proto ipv6-icmp accept

          # ==== inter-stack policy ====
          ip saddr 10.0.1.2 ip daddr 10.0.0.0/16 accept                 # traefik to all containers
          ip saddr 10.0.3.2 ip daddr 10.0.5.2 tcp dport 7878 accept     # prowlar to radarr
          ip saddr 10.0.5.2 ip daddr 10.0.3.2 tcp dport 9696 accept     # radarr to prowlarr
          ip saddr 10.0.3.2 ip daddr 10.0.6.2 tcp dport 8989 accept     # prowlar to sonarr
          ip saddr 10.0.6.2 ip daddr 10.0.3.2 tcp dport 9696 accept     # sonarr to prowlarr
          ip saddr 10.0.5.2 ip daddr 10.0.4.2 tcp dport 8888 accept     # radarr to qbittorrent
          ip saddr 10.0.6.2 ip daddr 10.0.4.2 tcp dport 8888 accept     # sonarr to qbittorrent
          ip saddr 10.0.11.2 ip daddr 10.0.23.2 tcp dport 2283 accept   # dawarich to immich
          ip saddr 10.0.16.2 ip daddr 10.0.22.4 tcp dport 1883 accept   # frigate to mqtt
          ip saddr 10.0.22.2 ip daddr 10.0.16.2 tcp dport 5000 accept   # hass to frigate
          ip saddr 10.0.18.2 ip daddr 10.0.37.2 tcp dport 9428 accept   # grafana to victoria
          ip saddr 10.0.20.2 ip daddr 10.0.22.2 tcp dport 8123 accept   # appdaemon to hass
          ip saddr 10.0.20.2 ip daddr 10.0.22.4 tcp dport 1883 accept   # appdaemon to mqtt
          ip saddr 10.0.28.2 ip daddr 10.0.27.4 tcp dport 11434 accept  # qdrant to ollama
          ip saddr 10.0.30.5 ip daddr 10.0.27.4 tcp dport 11434 accept  # paperllama to ollama
          ip saddr 10.0.32.2 ip daddr 10.0.22.4 tcp dport 1883 accept   # teslamate to mqtt
          ip saddr 10.0.22.2 ip daddr 10.0.39.2 tcp dport 8095 accept   # hass to mass
          ip saddr 10.0.39.2 ip daddr 10.0.22.2 tcp dport 8123 accept   # mass to hass, for TTS
          ip saddr 10.0.39.2 ip daddr 10.0.33.2 tcp dport 8096 accept   # mass to jellyfin
          ip saddr 10.0.14.2 ip daddr 10.0.15.3 tcp dport 5432 accept   # metabase to fafi-db
          ip saddr 10.0.24.2 ip daddr 10.0.15.3 tcp dport 5432 accept   # jupyter to fafi-db
          ip saddr 10.0.31.2 ip daddr 10.0.15.3 tcp dport 5432 accept   # pgadmin to fafi-db
          ip saddr 10.0.31.2 ip daddr 10.0.22.3 tcp dport 5432 accept   # pgadmin to hass-db
          ip saddr 10.0.10.2 ip daddr 10.0.1.2 tcp dport 443 accept      # opencloud to traefik, for oidc, see OC service.nix

          # containers cant talk with each other unless overriden above
          ip saddr ${vars.net.zenki.containers.subnet} ip daddr ${vars.net.zenki.containers.subnet} drop

          # allow inbound and outbound from everywhere (policy is on sensei)
          ip daddr ${vars.net.zenki.containers.subnet} accept
          ip saddr ${vars.net.zenki.containers.subnet} accept


          ip6 saddr ${vars.net.zenki.containers.prefix6}:1001::2 ip6 daddr ${vars.net.zenki.containers.subnet6} accept                           # traefik to all containers
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1003::2 ip6 daddr ${vars.net.zenki.containers.prefix6}:1005::2 tcp dport 7878 accept     # prowlar to radarr
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1005::2 ip6 daddr ${vars.net.zenki.containers.prefix6}:1003::2 tcp dport 9696 accept     # radarr to prowlarr
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1003::2 ip6 daddr ${vars.net.zenki.containers.prefix6}:1006::2 tcp dport 8989 accept     # prowlar to sonarr
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1006::2 ip6 daddr ${vars.net.zenki.containers.prefix6}:1003::2 tcp dport 9696 accept     # sonarr to prowlarr
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1005::2 ip6 daddr ${vars.net.zenki.containers.prefix6}:1004::2 tcp dport 8888 accept     # radarr to qbittorrent
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1006::2 ip6 daddr ${vars.net.zenki.containers.prefix6}:1004::2 tcp dport 8888 accept     # sonarr to qbittorrent
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1011::2 ip6 daddr ${vars.net.zenki.containers.prefix6}:1023::2 tcp dport 2283 accept     # dawarich to immich
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1016::2 ip6 daddr ${vars.net.zenki.containers.prefix6}:1022::4 tcp dport 1883 accept     # frigate to mqtt
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1022::2 ip6 daddr ${vars.net.zenki.containers.prefix6}:1016::2 tcp dport 5000 accept     # hass to frigate
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1018::2 ip6 daddr ${vars.net.zenki.containers.prefix6}:1037::2 tcp dport 9428 accept     # grafana to victoria
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1020::2 ip6 daddr ${vars.net.zenki.containers.prefix6}:1022::2 tcp dport 8123 accept     # appdaemon to hass
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1020::2 ip6 daddr ${vars.net.zenki.containers.prefix6}:1022::4 tcp dport 1883 accept     # appdaemon to mqtt
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1028::2 ip6 daddr ${vars.net.zenki.containers.prefix6}:1027::4 tcp dport 11434 accept    # qdrant to ollama
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1030::5 ip6 daddr ${vars.net.zenki.containers.prefix6}:1027::4 tcp dport 11434 accept    # paperllama to ollama
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1032::2 ip6 daddr ${vars.net.zenki.containers.prefix6}:1022::4 tcp dport 1883 accept     # teslamate to mqtt
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1022::2 ip6 daddr ${vars.net.zenki.containers.prefix6}:1039::2 tcp dport 8095 accept     # hass to mass
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1039::2 ip6 daddr ${vars.net.zenki.containers.prefix6}:1033::2 tcp dport 8096 accept     # mass to jellyfin
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1014::2 ip6 daddr ${vars.net.zenki.containers.prefix6}:1015::3 tcp dport 5432 accept     # metabase to fafi-db
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1024::2 ip6 daddr ${vars.net.zenki.containers.prefix6}:1015::3 tcp dport 5432 accept     # jupyter to fafi-db
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1031::2 ip6 daddr ${vars.net.zenki.containers.prefix6}:1015::3 tcp dport 5432 accept     # pgadmin to fafi-db
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1031::2 ip6 daddr ${vars.net.zenki.containers.prefix6}:1022::3 tcp dport 5432 accept     # pgadmin to hass-db
          ip6 saddr ${vars.net.zenki.containers.prefix6}:1010::2 ip6 daddr ${vars.net.zenki.containers.prefix6}:1001::2 tcp dport 443 accept      # opencloud to traefik, for oidc, see OC service.nix
          ip saddr ${vars.net.zenki.containers.prefix6}:1001.2 ip daddr ${vars.net.zenki.containers.subnet6} accept                           # traefik to all containers
          ip saddr ${vars.net.zenki.containers.prefix6}:1003.2 ip daddr ${vars.net.zenki.containers.prefix6}:1005.2 tcp dport 7878 accept     # prowlar to radarr
          ip saddr ${vars.net.zenki.containers.prefix6}:1005.2 ip daddr ${vars.net.zenki.containers.prefix6}:1003.2 tcp dport 9696 accept     # radarr to prowlarr
          ip saddr ${vars.net.zenki.containers.prefix6}:1003.2 ip daddr ${vars.net.zenki.containers.prefix6}:1006.2 tcp dport 8989 accept     # prowlar to sonarr
          ip saddr ${vars.net.zenki.containers.prefix6}:1006.2 ip daddr ${vars.net.zenki.containers.prefix6}:1003.2 tcp dport 9696 accept     # sonarr to prowlarr
          ip saddr ${vars.net.zenki.containers.prefix6}:1005.2 ip daddr ${vars.net.zenki.containers.prefix6}:1004.2 tcp dport 8888 accept     # radarr to qbittorrent
          ip saddr ${vars.net.zenki.containers.prefix6}:1006.2 ip daddr ${vars.net.zenki.containers.prefix6}:1004.2 tcp dport 8888 accept     # sonarr to qbittorrent
          ip saddr ${vars.net.zenki.containers.prefix6}:1011.2 ip daddr ${vars.net.zenki.containers.prefix6}:1023.2 tcp dport 2283 accept     # dawarich to immich
          ip saddr ${vars.net.zenki.containers.prefix6}:1016.2 ip daddr ${vars.net.zenki.containers.prefix6}:1022.4 tcp dport 1883 accept     # frigate to mqtt
          ip saddr ${vars.net.zenki.containers.prefix6}:1022.2 ip daddr ${vars.net.zenki.containers.prefix6}:1016.2 tcp dport 5000 accept     # hass to frigate
          ip saddr ${vars.net.zenki.containers.prefix6}:1018.2 ip daddr ${vars.net.zenki.containers.prefix6}:1037.2 tcp dport 9428 accept     # grafana to victoria
          ip saddr ${vars.net.zenki.containers.prefix6}:1020.2 ip daddr ${vars.net.zenki.containers.prefix6}:1022.2 tcp dport 8123 accept     # appdaemon to hass
          ip saddr ${vars.net.zenki.containers.prefix6}:1020.2 ip daddr ${vars.net.zenki.containers.prefix6}:1022.4 tcp dport 1883 accept     # appdaemon to mqtt
          ip saddr ${vars.net.zenki.containers.prefix6}:1028.2 ip daddr ${vars.net.zenki.containers.prefix6}:1027.4 tcp dport 11434 accept    # qdrant to ollama
          ip saddr ${vars.net.zenki.containers.prefix6}:1030.5 ip daddr ${vars.net.zenki.containers.prefix6}:1027.4 tcp dport 11434 accept    # paperllama to ollama
          ip saddr ${vars.net.zenki.containers.prefix6}:1032.2 ip daddr ${vars.net.zenki.containers.prefix6}:1022.4 tcp dport 1883 accept     # teslamate to mqtt
          ip saddr ${vars.net.zenki.containers.prefix6}:1022.2 ip daddr ${vars.net.zenki.containers.prefix6}:1039.2 tcp dport 8095 accept     # hass to mass
          ip saddr ${vars.net.zenki.containers.prefix6}:1039.2 ip daddr ${vars.net.zenki.containers.prefix6}:1033.2 tcp dport 8096 accept     # mass to jellyfin
          ip saddr ${vars.net.zenki.containers.prefix6}:1014.2 ip daddr ${vars.net.zenki.containers.prefix6}:1015.3 tcp dport 5432 accept     # metabase to fafi-db
          ip saddr ${vars.net.zenki.containers.prefix6}:1024.2 ip daddr ${vars.net.zenki.containers.prefix6}:1015.3 tcp dport 5432 accept     # jupyter to fafi-db
          ip saddr ${vars.net.zenki.containers.prefix6}:1031.2 ip daddr ${vars.net.zenki.containers.prefix6}:1015.3 tcp dport 5432 accept     # pgadmin to fafi-db
          ip saddr ${vars.net.zenki.containers.prefix6}:1031.2 ip daddr ${vars.net.zenki.containers.prefix6}:1022.3 tcp dport 5432 accept     # pgadmin to hass-db

          # containers cant talk with each other unless overriden above
          ip6 saddr ${vars.net.zenki.containers.subnet6} ip6 daddr ${vars.net.zenki.containers.subnet6} drop

          # allow inbound and outbound from everywhere (policy is on sensei)
          ip6 daddr ${vars.net.zenki.containers.subnet6} accept   # allow inbound from everywhere (policy is on sensei)
          ip6 saddr ${vars.net.zenki.containers.subnet6} accept   # allow outbound to everywhere (policy is on sensei)
        }
      }
    '';
  };
  
  users.users.${vars.username}.extraGroups = [ "networkmanager" ];
}
