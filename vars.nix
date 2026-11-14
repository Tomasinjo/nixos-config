let
  username = "tom";
  homeDir = "/home/${username}";
  secrets = import ./secrets.nix;
in {
  inherit username;
  fullName = "Tom";

  net = (import ./net.nix { inherit secrets; }).net;

  dir = {
    home = homeDir;
    nixos_config = "${homeDir}/nixos-config";
    hoarder_data = "/hoarder-data";
    impo_data = "/impo-data";
    games = "/games_mx500";
    usb_mountpoint = "${homeDir}/mnt";
    scripts = "${homeDir}/scripts";
    certs = "${homeDir}/certs";
  };

  email = {
    tom = secrets.email.tom;
  };

  timeZone = "Europe/Ljubljana";

  containerUser = {
    name = "container-user";
    uid = 1111;
    gid = 1111;
  };
}
