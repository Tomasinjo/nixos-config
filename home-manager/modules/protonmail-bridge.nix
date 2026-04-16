{ pkgs, ... }: 
{
  home.packages = [ pkgs.protonmail-bridge ];

  systemd.user.services.protonmail-bridge = {
    Unit = {
      Description = "Proton Mail Bridge";
      After = [ "network.target" "gpg-agent.service" ];
    };
    Service = {
      Restart = "always";
      ExecStart = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --non-interactive";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}