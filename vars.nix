let
  # Base values
  username = "tom";
  homeDir = "/home/${username}";
  secrets = import ./secrets.nix;
in {
  # User configuration
  inherit username;
  fullName = "Tom";

  dir = {
    home = homeDir;
    nixos_config = "${homeDir}/nixos-config";
    hoarder_data = "/hoarder-data";
    impo_data = "/impo-data";
    usb_mountpoint = "${homeDir}/mnt";
    scripts = "${homeDir}/scripts";
    certs = "${homeDir}/certs";
    docker_root = "${homeDir}/docker";
  };

  email = {
    tom = secrets.email.tom;
  };

  dockerUser = {
    name = "docker-user";
    uid = 1111;
    gid = 1111;
  };

  networking = {
    domain = secrets.networking.domain;
    ipv4DNS = secrets.networking.ipv4DNS;
    ipv6DNS = secrets.networking.ipv6DNS;

    vlan10 = {
      ipv4 = {
        subnet =  secrets.networking.vlan10.ipv4.subnet;
        gateway = secrets.networking.vlan10.ipv4.gateway;
      };
      ipv6 = {
        subnet =  secrets.networking.vlan10.ipv6.subnet;
        gateway = secrets.networking.vlan10.ipv6.gateway;
      };
    };

    zenki = {
      hostname = "zenki";
      fqdn = secrets.networking.zenki.fqdn;
      interface_name = "eth10g";
      interface_mac = secrets.networking.zenki.interface_mac;
      vlan10 = {
        tag = 10;
	      ipv4Address = secrets.networking.zenki.vlan10.ipv4Address;
        ipv6Address = secrets.networking.zenki.vlan10.ipv6Address;
	      interface_name = "eth10g.10";
      };
    };
    lenko = {
      hostname = "lenko";
    };
    vps = {
      ipv4Address = secrets.networking.vps.ipv4Address;
    };
  };
}