{ pkgs, ... }:

{
  systemd.user.services = {
    wl-clip-persist = {
      Unit = {
        Description = "Keep Wayland clipboard contents alive";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard regular";
        Restart = "on-failure";
        RestartSec = 2;
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };

    cliphist = {
      Unit = {
        Description = "Wayland clipboard history";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
        Restart = "on-failure";
        RestartSec = 2;
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
