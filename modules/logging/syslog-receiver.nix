{ config, pkgs, lib, vars, ... }:

let
  syslogPort = 514;
  syslogIp = vars.net.sensei.mgmt-vlan.ipv4.gateway;
  logFile = "/var/log/offenders-ips.log";
in
{
  services.rsyslogd = {
    enable = true;
    defaultConfig = ''
      module(load="imudp")
      input(type="imudp" address="${syslogIp}" port="${toString syslogPort}")
      template(name="OnlyIP" type="string" string="%msg%\n")
      if $fromhost-ip == '${vars.net.zenki.common-vlan.ipv4Address}' then {
        action(type="omfile" file="${logFile}" template="OnlyIP")
      }
    '';
  };
}
