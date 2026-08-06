{ pkgs, ... }:

let
  customFonts = pkgs.stdenvNoCC.mkDerivation {
    pname = "custom-system-fonts";
    version = "1.0";

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      fontDir="$out/share/fonts/truetype/custom"
      install -dm755 "$fontDir"
      install -m0644 ${../../assets/fonts/DOOMNerdFont-SemiBold.ttf} "$fontDir/DOOMNerdFont-SemiBold.ttf"
      install -m0644 ${../../assets/fonts/Excalifont-Regular.ttf} "$fontDir/Excalifont-Regular.ttf"

      runHook postInstall
    '';
  };
in
{
  fonts = {
    packages = with pkgs; [
      customFonts
      nerd-fonts.caskaydia-cove
      iosevka
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      noto-fonts-lgc-plus
    ];

    fontconfig = {
      enable = true;

      defaultFonts = {
        sansSerif = [
          "Noto Sans"
          "Noto Sans CJK SC"
          "Noto Sans CJK JP"
          "Noto Sans CJK KR"
        ];

        serif = [
          "Noto Serif"
          "Noto Serif CJK SC"
          "Noto Serif CJK JP"
          "Noto Serif CJK KR"
        ];

        monospace = [
          "CaskaydiaCove Nerd Font"
          "Iosevka"
          "CaskaydiaCove NF"
        ];

        emoji = [
          "Noto Color Emoji"
        ];
      };

      localConf = ''
        <match target="font">
          <test name="family" compare="eq">
            <string>Iosevka</string>
          </test>
          <edit name="fontfeatures" mode="append">
            <string>liga off</string>
          </edit>
          <edit name="fontfeatures" mode="append">
            <string>calt off</string>
          </edit>
          <edit name="fontfeatures" mode="append">
            <string>dlig off</string>
          </edit>
        </match>

        <match target="font">
          <test name="family" compare="eq">
            <string>CaskaydiaCove Nerd Font</string>
          </test>
          <edit name="fontfeatures" mode="append">
            <string>liga on</string>
          </edit>
          <edit name="fontfeatures" mode="append">
            <string>calt on</string>
          </edit>
          <edit name="fontfeatures" mode="append">
            <string>dlig on</string>
          </edit>
        </match>
      '';
    };
  };
}
