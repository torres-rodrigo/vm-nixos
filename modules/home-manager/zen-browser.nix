{ inputs, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;

  librewolfStylePrefs = {
    # Telemetry, experiments, and reporting.
    "datareporting.healthreport.uploadEnabled" = false;
    "datareporting.policy.dataSubmissionEnabled" = false;
    "toolkit.telemetry.enabled" = false;
    "toolkit.telemetry.unified" = false;
    "toolkit.telemetry.archive.enabled" = false;
    "toolkit.telemetry.newProfilePing.enabled" = false;
    "toolkit.telemetry.shutdownPingSender.enabled" = false;
    "toolkit.telemetry.updatePing.enabled" = false;
    "toolkit.telemetry.bhrPing.enabled" = false;
    "toolkit.telemetry.firstShutdownPing.enabled" = false;
    "app.shield.optoutstudies.enabled" = false;
    "app.normandy.enabled" = false;
    "app.normandy.api_url" = "";
    "breakpad.reportURL" = "";
    "browser.tabs.crashReporting.sendReport" = false;

    # Privacy and tracking protection.
    "privacy.trackingprotection.enabled" = true;
    "privacy.trackingprotection.socialtracking.enabled" = true;
    "privacy.trackingprotection.cryptomining.enabled" = true;
    "privacy.trackingprotection.fingerprinting.enabled" = true;
    "privacy.resistFingerprinting" = true;
    "privacy.globalprivacycontrol.enabled" = true;
    "privacy.donottrackheader.enabled" = true;
    "network.cookie.cookieBehavior" = 5;
    "network.cookie.lifetimePolicy" = 0;

    # HTTPS and mixed content.
    "dom.security.https_only_mode" = true;
    "dom.security.https_only_mode_ever_enabled" = true;
    "security.mixed_content.block_display_content" = true;

    # WebRTC leak reduction.
    "media.peerconnection.ice.default_address_only" = true;
    "media.peerconnection.ice.no_host" = true;
    "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;

    # Search, suggestions, and speculative network requests.
    "browser.search.suggest.enabled" = false;
    "browser.urlbar.suggest.searches" = false;
    "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
    "browser.urlbar.suggest.quicksuggest.sponsored" = false;
    "browser.urlbar.quicksuggest.enabled" = false;
    "browser.urlbar.groupLabels.enabled" = false;
    "browser.newtabpage.activity-stream.feeds.telemetry" = false;
    "browser.newtabpage.activity-stream.telemetry" = false;
    "browser.newtabpage.activity-stream.showSponsored" = false;
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
    "browser.newtabpage.activity-stream.default.sites" = "";
    "network.dns.disablePrefetch" = true;
    "network.prefetch-next" = false;
    "network.predictor.enabled" = false;
    "network.http.speculative-parallel-limit" = 0;

    # Autofill, passwords, Pocket, and DRM.
    "browser.formfill.enable" = false;
    "extensions.formautofill.addresses.enabled" = false;
    "extensions.formautofill.creditCards.enabled" = false;
    "signon.rememberSignons" = false;
    "extensions.pocket.enabled" = false;
    "media.eme.enabled" = false;

    # Extension startup approval.
    "extensions.autoDisableScopes" = 0;
  };
in
{
  imports = [
    inputs.zen-browser.homeModules.default
  ];

  programs.zen-browser = {
    enable = true;

    policies = {
      DisableAppUpdate = true;
      DisableFeedbackCommands = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      OfferToSaveLogins = false;
    };

    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;

      settings = librewolfStylePrefs;

      extensions.packages =
        with inputs.firefox-addons.packages.${system}; [
          ublock-origin
        ];

      bookmarks = {
        force = true;
        settings = [
          {
            name = "NixOS";
            url = "https://nixos.org/";
          }
          {
            name = "Nix Search";
            bookmarks = [
              {
                name = "Packages";
                url = "https://search.nixos.org/packages";
              }
              {
                name = "Options";
                url = "https://search.nixos.org/options";
              }
            ];
          }
        ];
      };
    };
  };
}
