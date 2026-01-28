

{ pkgs, ... }:

let
  secrets = import ../secrets.nix;
  certSource = "${secrets.certs.web.path}/cock.crt";
  keySource = "${secrets.certs.web.path}/cock.key";
in
{
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
      };
    };
  };

  # The plugin adds "Virtual Machines" tab to Cockpit
  # not working yet, monitor https://github.com/NixOS/nixpkgs/pull/447043
  #environment.systemPackages = with pkgs; [
  #  cockpit-machines
  #];

  # Cockpit expects a directory /etc/cockpit/ws-certs.d/
  systemd.tmpfiles.rules = [
    "d /etc/cockpit/ws-certs.d 0755 root root -"
    "L+ /etc/cockpit/ws-certs.d/cockpit.cert - - - - ${certSource}"
    "L+ /etc/cockpit/ws-certs.d/cockpit.key - - - - ${keySource}"
  ];

  # Open the firewall
  networking.firewall.allowedTCPPorts = [ 9090 ];
}