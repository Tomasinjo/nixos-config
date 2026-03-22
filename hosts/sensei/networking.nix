{ config, lib, pkgs, vars, ... }:

{
  networking.hostName = vars.net.sensei.hostname;
  networking.domain = vars.net.domain;

  # Enable systemd-networkd for configuration
  networking.useNetworkd = true;
  systemd.network.enable = true;

  # Do not use legacy networking
  networking.useDHCP = false;

  # Use ethN instead of enp... naming
  networking.usePredictableInterfaceNames = true;

  # PPPoE setup
  services.pppd = {
    enable = true;
    peers = {
      wan = {
        config = ''
          plugin pppoe.so enp6s0
          user "${vars.net.sensei.ppoe.user}"
          password "${vars.net.sensei.ppoe.password}"
          defaultroute
          persist
          maxfail 0
          holdoff 5
          mtu 1420
          mru 1420
          noipdefault
          hide-password
          lcp-echo-interval 20
          lcp-echo-failure 3
        '';
      };
    };
  };

  # IP forwarding
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  systemd.network = {
    netdevs = {
      # Bond interface (LACP)
      "10-bond0" = {
        netdevConfig = {
          Name = "bond0";
          Kind = "bond";
        };
        bondConfig = {
          Mode = "802.3ad";
          TransmitHashPolicy = "layer2";
          MIIMonitorSec = "100ms";
        };
      };

      # VLANs
      "20-${vars.net.sensei.common-vlan.name}" = {
        netdevConfig = { Name = vars.net.sensei.common-vlan.name; Kind = "vlan"; };
        vlanConfig = { Id = vars.net.sensei.common-vlan.id; };
      };
      "20-${vars.net.sensei.guest-vlan.name}" = {
        netdevConfig = { Name = vars.net.sensei.guest-vlan.name; Kind = "vlan"; };
        vlanConfig = { Id = vars.net.sensei.guest-vlan.id; };
      };
      "20-${vars.net.sensei.iot-vlan.name}" = {
        netdevConfig = { Name = vars.net.sensei.iot-vlan.name; Kind = "vlan"; };
        vlanConfig = { Id = vars.net.sensei.iot-vlan.id; };
      };

      # Loopback for DNS
      "30-lo-dns" = {
        netdevConfig = {
          Name = "lo-dns";
          Kind = "dummy";
        };
      };
    };

    networks = {
      # WAN physical interface (PPPoE will attach here)
      "10-wan" = {
        matchConfig.Name = "enp6s0";
        networkConfig.LinkLocalAddressing = "no";
        # Bring it up so pppd can use it
        linkConfig.ActivationPolicy = "always-up";
      };

      # Bond slaves (igb1-igb4)
      "10-bond-slaves" = {
        matchConfig.Name = "enp2s0 enp3s0 enp4s0 enp5s0";
        networkConfig.Bond = "bond0";
      };

      # Bond interface configuration
      "20-bond0" = {
        matchConfig.Name = "bond0";
        networkConfig = {
          VLAN = [
            vars.net.sensei.common-vlan.name
            vars.net.sensei.guest-vlan.name
            vars.net.sensei.iot-vlan.name
          ];
          Address = [ 
            "${vars.net.sensei.vlan99.ipv4.gateway}/24" 
            "${vars.net.sensei.vlan99.ipv6.gateway}/64" 
          ];
        };
      };

      # VLAN 10 (Services)
      "30-${vars.net.sensei.common-vlan.name}" = {
        matchConfig.Name = vars.net.sensei.common-vlan.name;
        networkConfig = {
          Address = [ 
            "${vars.net.sensei.common-vlan.ipv4.gateway}/24"
            "${vars.net.sensei.common-vlan.ipv6.gateway}/64"
          ];
        };
      };

      # VLAN 20 (Guest)
      "30-${vars.net.sensei.guest-vlan.name}" = {
        matchConfig.Name = vars.net.sensei.guest-vlan.name;
        networkConfig = {
          Address = [ 
            "${vars.net.sensei.guest-vlan.ipv4.gateway}/24"
            "${vars.net.sensei.guest-vlan.ipv6.gateway}/64"
          ];
        };
      };

      # VLAN 30 (IoT)
      "30-${vars.net.sensei.iot-vlan.name}" = {
        matchConfig.Name = vars.net.sensei.iot-vlan.name;
        networkConfig = {
          Address = [ 
            "${vars.net.sensei.iot-vlan.ipv4.gateway}/24"
            "${vars.net.sensei.iot-vlan.ipv6.gateway}/64"
          ];
        };
      };

      # Dummy interface for DNS (opt5)
      "40-lo-dns" = {
        matchConfig.Name = "lo-dns";
        networkConfig = {
          Address = [ 
            "${vars.net.sensei.ipv4DNS}/32" 
            "${vars.net.sensei.ipv6DNS}/128" 
          ];
        };
      };
      
      # PPP interface
      "50-ppp" = {
        matchConfig.Name = "ppp*";
        networkConfig.DHCP = "ipv6";
        networkConfig.IPv6AcceptRA = true;
        networkConfig.KeepConfiguration = "static";
      };
    };
  };
}
