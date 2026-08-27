{ config, pkgs, vars, ... }:

{
  networking.hostName = vars.net.zenki.hostname;
  networking.useNetworkd = true;
  networking.useDHCP = false;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv4.conf.default.forwarding" = 1;

    # Prevents kernel from dropping inter-bridge container traffic
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;

    # Prevents Docker's bridge netfilter from mangling routed packets
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
      vars.net.zenki.common-vlan.interface_name
      vars.net.zenki.lab-vlan.interface_name
    ];
  };

  # Configure VLAN 10 Interface
  systemd.network.netdevs."10-${vars.net.sensei.common-vlan.name}" = {
    netdevConfig = {
      Name = vars.net.zenki.common-vlan.interface_name;
      Kind = "vlan";
    };
    vlanConfig.Id = vars.net.sensei.common-vlan.id;
  };

  # IP Configuration for VLAN 10
  systemd.network.networks."20-${vars.net.sensei.common-vlan.name}" = {
    matchConfig.Name = vars.net.zenki.common-vlan.interface_name;
    address = [
      "${vars.net.zenki.common-vlan.ipv4Address}/${vars.net.sensei.common-vlan.ipv4.mask}"
      "${vars.net.zenki.common-vlan.ipv6Address}/${vars.net.sensei.common-vlan.ipv6.mask}"
    ];
    routes = [
      { Gateway = vars.net.sensei.common-vlan.ipv4.gateway; }
      { Gateway = vars.net.sensei.common-vlan.ipv6.gateway; }
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

  # Firewall
  networking.firewall = {
      enable = true;
      allowPing = true;
  
      # default deny all
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
  
      # allowed ports for system services
      interfaces."${vars.net.zenki.common-vlan.interface_name}" = {
        allowedTCPPorts = [ 22 ]; # SSH
      };
  
      trustedInterfaces = [ "docker0" ];
      checkReversePath = "loose";
  };

  systemd.services.docker-routed-firewall = {
    description = "Apply Docker Routed Supernet Firewall & Routing Rules";
    after = [ "docker.service" "firewall.service" ];
    wants = [ "docker.service" "firewall.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "docker-routed-firewall" ''
        # A. Disable bridge netfilter (Docker re-enables this on boot)
        ${pkgs.procps}/bin/sysctl -w net.bridge.bridge-nf-call-iptables=0 || true
        ${pkgs.procps}/bin/sysctl -w net.bridge.bridge-nf-call-ip6tables=0 || true
        ${pkgs.procps}/bin/sysctl -w net.bridge.bridge-nf-call-arptables=0 || true

        # B. Enable forwarding and disable rp_filter on dynamic veth/bridge interfaces
        for f in /proc/sys/net/ipv4/conf/*/forwarding; do echo 1 > $f; done
        for f in /proc/sys/net/ipv4/conf/*/rp_filter; do echo 0 > $f; done

        # C. Raw Table: Allow inbound & outbound supernet traffic
        ${pkgs.iptables}/bin/iptables -t raw -I PREROUTING 1 -s 10.0.0.0/16 -j ACCEPT 2>/dev/null || true
        ${pkgs.iptables}/bin/iptables -t raw -I PREROUTING 2 -d 10.0.0.0/16 -j ACCEPT 2>/dev/null || true

        # D. Mangle Table: Bypass NixOS rpfilter for the container supernet
        ${pkgs.iptables}/bin/iptables -t mangle -I nixos-fw-rpfilter 1 -s 10.0.0.0/16 -j RETURN 2>/dev/null || true

        # E. Forwarding: Allow all outbound, inter-container, and return traffic
        ${pkgs.iptables}/bin/iptables -I FORWARD 1 -d 10.0.0.0/16 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
        ${pkgs.iptables}/bin/iptables -I FORWARD 2 -s 10.0.0.0/16 -j ACCEPT
        ${pkgs.iptables}/bin/iptables -I DOCKER-USER 1 -d 10.0.0.0/16 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
        ${pkgs.iptables}/bin/iptables -I DOCKER-USER 2 -s 10.0.0.0/16 -j ACCEPT

        # F. NAT Rules: Placed at Rule #1 above Docker's 40+ rules
        ${pkgs.iptables}/bin/iptables -t nat -I POSTROUTING 1 -s 10.0.0.0/16 -d 10.0.0.0/16 -j ACCEPT
        ${pkgs.iptables}/bin/iptables -t nat -I POSTROUTING 2 -s 10.0.0.0/16 -d 192.168.10.0/24 -j MASQUERADE
        ${pkgs.iptables}/bin/iptables -t nat -I POSTROUTING 3 -s 10.0.0.0/16 -j ACCEPT
      '';
    };
  };
  
  users.users.${vars.username}.extraGroups = [ "networkmanager" ];
}
