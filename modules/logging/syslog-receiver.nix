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
      if $fromhost-ip == '192.168.10.15' then {
        *.* ?OnlyIP;${logFile}
      }
    '';
  };

  # create log file
  systemd.tmpfiles.rules = [
    "f ${logFile} 0644 root root -"
    "f /var/log/offenders.log 0644 root root -"
  ];
}
