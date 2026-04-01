{ config, lib, pkgs, vars, ... }:

{
  systemd.network = {
    netdevs = {
      "90-wg0" = {
        netdevConfig = {
          Name = "wg0";
          Kind = "wireguard";
        };
        wireguardConfig = {
          PrivateKeyFile = "/etc/systemd/network/wireguard.key";
          ListenPort = 8080;
        };
        wireguardPeers = [
          {
            PublicKey = vars.net.sensei.wireguard.clients.tom.pub_key;
            AllowedIPs = [
              "${vars.net.sensei.wireguard.clients.tom.ipv4}/32"
              "${vars.net.sensei.wireguard.clients.tom.ipv6}/128" 
            ];
          }
        ];
      };
    };

    networks = {
      "90-wg0" = {
        matchConfig.Name = "wg0";
        networkConfig = {
          Address = [
            "${vars.net.sensei.wireguard.ipv4.gateway}/24"
            "${vars.net.sensei.wireguard.ipv6.gateway}/64"
          ];
        };
      };
    };
  };
}
