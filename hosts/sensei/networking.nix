{ config, lib, pkgs, vars, ... }:

{
  networking.hostName = vars.net.sensei.hostname;
  networking.domain = vars.net.domain;

  # Enable systemd-networkd for configuration
  networking.useNetworkd = true;
  systemd.network.enable = true;

  networking.useDHCP = false;
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
      "20-${vars.net.sensei.server-vlan.name}" = {
        netdevConfig = { Name = vars.net.sensei.server-vlan.name; Kind = "vlan"; };
        vlanConfig = { Id = vars.net.sensei.server-vlan.id; };
      };
      "20-${vars.net.sensei.lab-vlan.name}" = {
        netdevConfig = { Name = vars.net.sensei.lab-vlan.name; Kind = "vlan"; };
        vlanConfig = { Id = vars.net.sensei.lab-vlan.id; };
      };

      # Loopback for DNS
      "30-lo-dns" = {
        netdevConfig = {
          Name = "lo-dns";
          Kind = "dummy";
        };
      };
      
      # Loopback for wg, resolves AAAA vpn....
      "30-lo-wg" = {
        netdevConfig = {
          Name = "lo-wg";
          Kind = "dummy";
        };
      };
    };
      

    networks = {
      # WAN physical interface
      "10-wan" = {
        matchConfig.Name = "enp6s0";
        networkConfig.LinkLocalAddressing = "no";
        # Bring it up so pppd can use it
        linkConfig.ActivationPolicy = "always-up";
      };

      # LACP slaves
      "10-bond-slaves" = {
        matchConfig.Name = "enp2s0 enp3s0 enp4s0 enp5s0";
        networkConfig.Bond = "bond0";
      };

      # LACP config
      "20-bond0" = {
        matchConfig.Name = "bond0";
        networkConfig = {
          VLAN = [
            vars.net.sensei.common-vlan.name
            vars.net.sensei.guest-vlan.name
            vars.net.sensei.iot-vlan.name
            vars.net.sensei.server-vlan.name
            vars.net.sensei.lab-vlan.name
          ];
          Address = [ 
            "${vars.net.sensei.mgmt-vlan.ipv4.gateway}/24" 
            "${vars.net.sensei.mgmt-vlan.ipv6.gateway}/64" 
          ];
        };
      };

      # VLAN 10 (Services)
      "30-${vars.net.sensei.common-vlan.name}" = {
        matchConfig.Name = vars.net.sensei.common-vlan.name;
        networkConfig = {
          Address = [ 
            "${vars.net.sensei.common-vlan.ipv4.gateway}/${vars.net.sensei.common-vlan.ipv4.mask}"
            "${vars.net.sensei.common-vlan.ipv6.gateway}/${vars.net.sensei.common-vlan.ipv6.mask}"
          ];
          IPv6SendRA = "yes";
        };
        ipv6SendRAConfig = {
          Managed = false;         # turn off dhcpv6 
          OtherInformation = false; # turn off dhcpv6 for dns
          EmitDNS = true;  # include dns in RA, for slaac
          DNS = vars.net.sensei.ipv6DNS;
          EmitDomains = true; # include domain in RA, for slaac
          Domains = vars.net.domain;
        };
        # include prefix information option in RA. wasn't included without it.
        ipv6Prefixes = [
          {
            Prefix = "${vars.net.sensei.common-vlan.ipv6.subnet}/${vars.net.sensei.common-vlan.ipv6.mask}";
          }
        ];
      };

      # VLAN 20 (Guest)
      "30-${vars.net.sensei.guest-vlan.name}" = {
        matchConfig.Name = vars.net.sensei.guest-vlan.name;
        networkConfig = {
          Address = [ 
            "${vars.net.sensei.guest-vlan.ipv4.gateway}/${vars.net.sensei.guest-vlan.ipv4.mask}"
            "${vars.net.sensei.guest-vlan.ipv6.gateway}/${vars.net.sensei.guest-vlan.ipv6.mask}"
          ];
          IPv6SendRA = "yes";
        };
        ipv6SendRAConfig = {
          Managed = false;
          OtherInformation = false;
          EmitDNS = true;
          DNS = "2606:4700:4700::1111";
        };
        ipv6Prefixes = [
          {
            Prefix = "${vars.net.sensei.guest-vlan.ipv6.subnet}/${vars.net.sensei.guest-vlan.ipv6.mask}";
          }
        ];
      };

      # VLAN 30 (IoT)
      "30-${vars.net.sensei.iot-vlan.name}" = {
        matchConfig.Name = vars.net.sensei.iot-vlan.name;
        networkConfig = {
          Address = [ 
            "${vars.net.sensei.iot-vlan.ipv4.gateway}/${vars.net.sensei.iot-vlan.ipv4.mask}"
            "${vars.net.sensei.iot-vlan.ipv6.gateway}/${vars.net.sensei.iot-vlan.ipv6.mask}"
          ];
          IPv6SendRA = "no";
        };
      };

      # Server VLAN 40
      "30-${vars.net.sensei.server-vlan.name}" = {
        matchConfig.Name = vars.net.sensei.server-vlan.name;
        networkConfig = {
          Address = [ 
            "${vars.net.sensei.server-vlan.ipv4.gateway}/${vars.net.sensei.server-vlan.ipv4.mask}"
            "${vars.net.sensei.server-vlan.ipv6.gateway}/${vars.net.sensei.server-vlan.ipv6.mask}"
          ];
          IPv6SendRA = "yes";
        };
        routes = [
            # static route for podman container networks since SNAT is disabled in podman
            # this is for return traffic since containers now use their IP for outbound connections.
            # zenki act as a router with this network behind it.
          {
            routeConfig = {
              Destination = vars.net.zenki.containers.subnet;
              Gateway = vars.net.zenki.server-vlan.ipv4Address;
            };
          }
          {
            routeConfig = {
              Destination = vars.net.zenki.containers.subnet6;
              Gateway = vars.net.zenki.server-vlan.ipv6Address;
            };
          }
        ];
      };

      # VLAN 69 (Lab)
      "30-${vars.net.sensei.lab-vlan.name}" = {
        matchConfig.Name = vars.net.sensei.lab-vlan.name;
        networkConfig = {
          Address = [
            "${vars.net.sensei.lab-vlan.ipv4.gateway}/${vars.net.sensei.lab-vlan.ipv4.mask}"
          ];
        };
      };

      # loopback interface for DNS
      "40-lo-dns" = {
        matchConfig.Name = "lo-dns";
        networkConfig = {
          Address = [
            "${vars.net.sensei.ipv4DNS}/32" 
            "${vars.net.sensei.ipv6DNS}/128" 
          ];
        };
      };
 
      # loopback interface for wg public AAAA vpn....
      "40-lo-wg" = {
        matchConfig.Name = "lo-wg";
        networkConfig = {
          Address = [
            "${vars.net.sensei.wireguard.ipv6.public_if}/128" 
          ];
        };
      };


      # PPP interface
      "50-ppp" = {
        matchConfig.Name = "ppp*";
        networkConfig = {
          DHCP = "ipv6"; # dhcp client
          IPv6AcceptRA = true; # provides dns servers, i dont use them, just playing it nicely
        };
	      dhcpV6Config = {
	        PrefixDelegationHint = "::/56"; # request prefix with prefix delegation IA_PD
	        UseDelegatedPrefix = true; # probably not necessary since prefix is statically defined
	        WithoutRA = "solicit";   # ask for ip without instructions in RA
	        RapidCommit = false;  # dont skip dhcp messages
	        UseAddress = false;   # do not request wan ip IA_NA
	      };
      };
    };
    links = {
      "20-suricata-vlans" = {
        matchConfig.OriginalName = "${vars.net.sensei.common-vlan.name} ${vars.net.sensei.iot-vlan.name} bond0 enp2s0 enp3s0 enp4s0 enp5s0";
        linkConfig = {
          GenericReceiveOffload = false;       # gro off
          GenericSegmentationOffload = false;  # gso off
          TCPSegmentationOffload = false;      # tso off
          LargeReceiveOffload = false;         # lro off
        };
      };
    };
  };
}
