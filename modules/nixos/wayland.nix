{ pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.xwayland.enable = true;

  security.polkit.enable = true;

  services.seatd.enable = true;

  xdg = {
    icons.enable = true;
    menus.enable = true;
    mime.enable = true;

    terminal-exec = {
      enable = true;
      settings.default = [
        "foot.desktop"
      ];
    };

    portal = {
      enable = true;
      config = {
        common.default = [
          "gtk"
        ];
      };
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
      wlr.enable = true;
      xdgOpenUsePortal = true;
    };
  };

  environment = {
    sessionVariables = {
      GDK_BACKEND = "wayland,x11";
      MOZ_ENABLE_WAYLAND = "1";
      NIXOS_OZONE_WL = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      SDL_VIDEODRIVER = "wayland,x11";
      XDG_SESSION_TYPE = "wayland";
      _JAVA_AWT_WM_NONREPARENTING = "1";
    };

    systemPackages = with pkgs; [
      cliphist
      grim
      libnotify
      mako
      qt6.qtwayland
      qt5.qtwayland
      rofi
      satty
      slurp
      swaybg
      wev
      wayland-utils
      wl-clip-persist
      wl-clipboard
      wlr-randr
    ];
  };
}
