{ config, pkgs, lib, vars, ... }:

let
  syslogPort = 514;
  syslogIp = vars.net.sensei.mgmt-vlan.ipv4.gateway;
  logFile = "/var/log/offenders-ips.log";
in
{
  services.rsyslogd = {
    enable = true;
    # rawmsg is used because the syslog is not standard compliant as it only sends ip 
    defaultConfig = ''
      module(load="imudp")
      input(type="imudp" address="${syslogIp}" port="${toString syslogPort}")
      template(name="OnlyIP" type="string" string="%rawmsg:::drop-last-lf%\n")
      if $fromhost-ip == '${vars.net.zenki.server-vlan.ipv4Address}' then {
        action(type="omfile" file="${logFile}" template="OnlyIP")
      }
    '';
  };
}
