{ config, pkgs, lib, vars, ... }:


# list (set) is called "addr-set-offenders"
# table is called "f2b-table"

{
  services.fail2ban = {
    enable = true;
    banaction = "nftables-allports";
    bantime = "30d";

    ignoreIP = [
      "10.0.0.0/8"
      "172.16.0.0/12"
      "192.168.0.0/16"
      "fe80::/10"
      "fc00::/7"
      "${vars.net.sensei.ipv6_prefix}"
      "${vars.net.sensei.ipv4_public}/32"
    ];

    jails = {
      offenders = {
        filter = {
          Definition = {
            datepattern = ''"time"\s*:\s*"%%Y-%%m-%%dT%%H:%%M:%%S%%z'';
            failregex = ''"ClientHost"\s*:\s*"<ADDR>"'';
            ignoreregex = "";
          };
        };

        settings = {
          action = ''nftables-allports'';
          logpath = "/var/log/offenders-ips.log";
          backend = "auto";
          maxretry = 3;
          findtime = "1d";
        };
      };
    };
  };
  
  # use prerouting else input chain is used which happens later than DNAT causing rule not to be evaluated
  # priority is there to make sure it happens before dnat
  environment.etc."fail2ban/action.d/nftables-common.local".text = ''
    [Init]
    chain_hook = prerouting
    chain_priority = -150
  '';
}
