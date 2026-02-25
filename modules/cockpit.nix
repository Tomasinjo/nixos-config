# attempt from this pull request. VM tab is not visible, need to figure it out.
# https://github.com/NixOS/nixpkgs/pull/447043

{ pkgs, ... }:

let
  secrets = import ../secrets.nix;
  certSource = "${secrets.certs.web.path}/zenki.crt";
  keySource = "${secrets.certs.web.path}/zenki.key";
in
{
  users = {
    users.libvirtdbus = {
      isSystemUser = true;
      group = "libvirtdbus";
      description = "Libvirt D-Bus bridge";
    };
    groups.libvirtdbus = {};
  };

  systemd.packages = with pkgs; [ 
    libvirt-dbus 
  ];

  environment.systemPackages = with pkgs; [
    virt-manager
    libvirt-dbus

    cockpit
    (cockpit-machines.overrideAttrs (finalAttrs: previousAttrs: let
      python_with_gio = (
        pkgs.python3.withPackages (
          ps: with ps; [
            pygobject3
          ]
        )
      );
    in {
      postPatch = previousAttrs.postPatch + ''
        substituteInPlace pkg/lib/python.ts --replace-fail "/usr/libexec/platform-python" "${python_with_gio.interpreter}"
      '';

      postInstall = ''
        substituteInPlace $out/share/cockpit/machines/index.js \
         --replace-fail 'var pyinvoke = [' \
         'var pyinvoke = ["env",
           "GI_TYPELIB_PATH=${libosinfo}/lib/girepository-1.0:${glib.out}/lib/girepository-1.0:${pkgs.gobject-introspection}/lib/girepository-1.0",
           "XDG_DATA_DIRS=${libosinfo}/share:${osinfo-db}/share",
         '
      '';
    }))
  ];

  services.cockpit = {
    enable = true;
    openFirewall = true;
    allowed-origins = [ "*" ];
  };

  virtualisation = {
    libvirtd.enable = true;
  };

  # Cockpit expects a directory /etc/cockpit/ws-certs.d/
  systemd.tmpfiles.rules = [
    "d /etc/cockpit/ws-certs.d 0755 root root -"
    "L+ /etc/cockpit/ws-certs.d/cockpit.cert - - - - ${certSource}"
    "L+ /etc/cockpit/ws-certs.d/cockpit.key - - - - ${keySource}"
  ];

  # Open the firewall
  networking.firewall.allowedTCPPorts = [ 9090 ];
}
