{ lib, pkgs, ... }:

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

  featureNames = [
    "liga"
    "calt"
    "dlig"
  ];

  fontFeatureProfiles = {
    iosevka = {
      families = [
        "Iosevka"
      ];

      features = {
        liga = false;
        calt = false;
        dlig = false;
      };
    };

    caskaydiaCove = {
      families = [
        "CaskaydiaCove Nerd Font"
        "CaskaydiaCove NF"
      ];

      features = {
        liga = true;
        calt = true;
        dlig = true;
      };
    };
  };

  fontFeatureValue = features: name:
    "            <string>${name} ${if features.${name} then "on" else "off"}</string>";

  fontFeatureMatch = profile: family: ''
        <match target="font">
          <test name="family" compare="eq">
            <string>${family}</string>
          </test>
          <edit name="fontfeatures" mode="assign_replace">
${lib.concatMapStringsSep "\n" (fontFeatureValue profile.features) featureNames}
          </edit>
        </match>
  '';

  fontFeatureConf =
    lib.concatMapStringsSep "\n" (
      profile:
      lib.concatMapStringsSep "\n" (fontFeatureMatch profile) profile.families
    ) (lib.attrValues fontFeatureProfiles);
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

      localConf = fontFeatureConf;
    };
  };
}
