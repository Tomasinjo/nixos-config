{ config, lib, pkgs, vars, ... }:

let
  containers = config.virtualisation.oci-containers.containers;
  cip4 = name: containers.${name}.labels."address.ipv4";
  cip6 = name: containers.${name}.labels."address.ipv6";

  # inter-stack policy: which containers may talk to each other directly.
  # names are oci-containers attrset keys and match the *.zenki.internal dns
  # records served by sensei, everything not listed here is dropped below.
  # to = null means all containers, port is tcp only.
  interStack = [
    { from = "traefik-app"; to = null; }
    { from = "traefik-gatekeeper"; to = "opencloud-app"; port = 9200; }
    { from = "traefik-gatekeeper"; to = "immich-app"; port = 2283; }
    { from = "traefik-gatekeeper"; to = "mealie-app"; port = 9000; }
    { from = "prowlarr-app"; to = "radarr-app"; port = 7878; }
    { from = "radarr-app"; to = "prowlarr-app"; port = 9696; }
    { from = "prowlarr-app"; to = "sonarr-app"; port = 8989; }
    { from = "sonarr-app"; to = "prowlarr-app"; port = 9696; }
    { from = "radarr-app"; to = "qbittorrent-app"; port = 8888; }
    { from = "sonarr-app"; to = "qbittorrent-app"; port = 8888; }
    { from = "dawarich-app"; to = "immich-app"; port = 2283; }
    { from = "frigate-app"; to = "home-assistant-mqtt"; port = 1883; }
    { from = "home-assistant-app"; to = "frigate-app"; port = 5000; }
    { from = "grafana-app"; to = "victoriametrics-app"; port = 9428; }
    { from = "appdaemon-app"; to = "home-assistant-app"; port = 8123; }
    { from = "appdaemon-app"; to = "home-assistant-mqtt"; port = 1883; }
    { from = "qdrant-app"; to = "ollama-app"; port = 11434; }
    { from = "paperless-paperllama"; to = "ollama-app"; port = 11434; }
    { from = "teslamate-app"; to = "home-assistant-mqtt"; port = 1883; }
    { from = "home-assistant-app"; to = "music-assistant-app"; port = 8095; }
    { from = "music-assistant-app"; to = "home-assistant-app"; port = 8123; }  # TTS
    { from = "music-assistant-app"; to = "jellyfin-app"; port = 8096; }
    { from = "metabase-app"; to = "nocodb-db"; port = 5432; }
    { from = "jupyter-app"; to = "nocodb-db"; port = 5432; }
    { from = "pgadmin-app"; to = "nocodb-db"; port = 5432; }
    { from = "pgadmin-app"; to = "home-assistant-db"; port = 5432; }
    { from = "opencloud-app"; to = "traefik-app"; port = 443; }  # oidc, see OC service.nix
    { from = "euro-office-app"; to = "opencloud-app"; port = 9300; }
    { from = "hermes-app"; to = "ollama-app"; port = 11434; }
    { from = "hermes-app"; to = "fatracker-ng-app"; port = 8000; }  # MCP
    { from = "dr_sre-app"; to = "ollama-app"; port = 11434; }
    { from = "dr_sre-app"; to = "victoriametrics-app"; port = 9428; }
    { from = "mealie-app"; to = "ollama-app"; port = 11434; }
    { from = "grafana-app"; to = "fatracker-ng-db"; port = 5432; }
    { from = "pgadmin-app"; to = "fatracker-ng-db"; port = 5432; }
    { from = "glance-app"; to = "dockerproxy-app"; port = 2375; }
    { from = "hermes-app"; to = "grocy-app"; port = 80; }
    { from = "hermes-app"; to = "grocy-b2g"; port = 8000; }
    { from = "grocy-b2g"; to = "hermes-app"; port = 8644; } # webhook
  ];

  mkInterStack = family: ip: subnet:
    lib.concatMapStringsSep "\n    " (r:
      let
        dst = if r.to == null then subnet else ip r.to;
        port = lib.optionalString (r ? port) "tcp dport ${toString r.port} ";
      in
      "${family} saddr ${ip r.from} ${family} daddr ${dst} ${port}accept"
    ) interStack;

in
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
      table inet filter {
        chain input {
          type filter hook input priority filter; policy drop;

          iifname "lo" accept
          ct state { established, related } accept

          iifname "${vars.net.zenki.server-vlan.interface_name}" tcp dport 22 accept
          iifname "${vars.net.zenki.server-vlan.interface_name}" tcp dport 9119 accept

          # polaris game stream
          iifname "${vars.net.zenki.server-vlan.interface_name}" udp dport 5353 accept # mDNS discovery (avahi)
          iifname "${vars.net.zenki.server-vlan.interface_name}" tcp dport { 47984, 47989, 47990, 48010 } accept
          iifname "${vars.net.zenki.server-vlan.interface_name}" udp dport { 47998, 47999, 48000, 48010 } accept

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

          # inter-stack policy, generated from the interStack list 
          ${mkInterStack "ip" cip4 vars.net.zenki.containers.subnet}
          ${mkInterStack "ip6" cip6 vars.net.zenki.containers.subnet6}

          # containers cant talk with each other unless overriden above
          ip saddr ${vars.net.zenki.containers.subnet} ip daddr ${vars.net.zenki.containers.subnet} drop
          ip6 saddr ${vars.net.zenki.containers.subnet6} ip6 daddr ${vars.net.zenki.containers.subnet6} drop

          # allow inbound and outbound from everywhere (policy is on sensei)
          ip daddr ${vars.net.zenki.containers.subnet} accept
          ip saddr ${vars.net.zenki.containers.subnet} accept
          ip6 daddr ${vars.net.zenki.containers.subnet6} accept
          ip6 saddr ${vars.net.zenki.containers.subnet6} accept
        }
      }
    '';
  };
  
  users.users.${vars.username}.extraGroups = [ "networkmanager" ];
}
