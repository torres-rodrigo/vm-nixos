# Zen Browser Plan

## Requirements

Add Zen Browser to this flake-based NixOS configuration as a system-wide
browser package.

User requirements:

- Zen Browser must be installed system-wide through NixOS, not only as a
  per-user Home Manager package.
- Zen must ship with a hardened LibreWolf-style privacy and security baseline.
- Hardened settings should be applied as defaults where possible, not locked
  policies, so manual changes made inside Zen are remembered later.
- Extensions must be easy to add from the Nix config.
- Extensions should come from packaged Firefox add-ons, using the rycee/NUR
  Firefox add-ons package set.
- Bookmarks must be easy to add from the Nix config.
- Home Manager must stay integrated through the NixOS module system. The user
  must not need to run `home-manager switch` separately.
- Validation must use the project flake and the normal NixOS rebuild flow.

Reference material:

- Zen Browser NixOS wiki:
  `https://wiki.nixos.org/wiki/Zen_Browser`
- Zen Browser flake with Home Manager/profile support:
  `https://github.com/0xc000022070/zen-browser-flake`
- Home Manager Firefox options, used by Firefox-derived browser modules:
  `https://nix-community.github.io/home-manager/options/home-manager/programs/firefox.html`
- LibreWolf settings reference:
  `https://librewolf.net/docs/settings/`

## Current Repository State

The repository already has a focused browser module:

- `modules/nixos/browser.nix`

At the time this plan was written, that module only enables Firefox:

```nix
{ ... }:

{
  programs.firefox.enable = true;
}
```

The shared package baseline lives in:

- `modules/nixos/packages.nix`

Do not add Zen to the general package dump there. Browser ownership already has
a focused module, so Zen belongs in `modules/nixos/browser.nix`.

Home Manager is already integrated through the NixOS module system:

- `modules/nixos/home-manager.nix`
- `users/r/home.nix`
- `modules/home-manager/programs.nix`

Add Zen user/profile configuration as a Home Manager module and import it
through `modules/home-manager/programs.nix`.

The current pinned `nixpkgs` input does not expose `pkgs.zen-browser`, so use a
Zen Browser flake input instead of assuming the package exists in nixpkgs.

## Architecture

Use a split design:

- NixOS owns system-wide installation.
- Home Manager owns user-scoped Zen profile configuration.

System-wide package:

- Add the Zen flake package to `environment.systemPackages` in
  `modules/nixos/browser.nix`.
- Keep Firefox as a temporary fallback for the first Zen rollout unless the user
  explicitly asks to remove it.

User profile configuration:

- Add a new Home Manager module, for example
  `modules/home-manager/zen-browser.nix`.
- Import the Zen Browser Home Manager module from the Zen flake.
- Configure `programs.zen-browser`.
- Put hardening preferences, extensions, and bookmarks in the default Zen
  profile.

Flake input plumbing:

- Pass the top-level `inputs` attrset to NixOS modules through `specialArgs`.
- Pass the same `inputs` attrset to Home Manager modules through
  `home-manager.extraSpecialArgs`.
- This lets both NixOS and Home Manager modules reference the Zen Browser flake
  and the Firefox add-ons flake without hardcoding paths.

## Implementation Steps

1. Update `flake.nix`.

   Change the output argument pattern to keep the full input set available:

   ```nix
   outputs = inputs @ { home-manager, nixpkgs, ... }:
   ```

   Add inputs:

   ```nix
   zen-browser = {
     url = "github:0xc000022070/zen-browser-flake";
     inputs.nixpkgs.follows = "nixpkgs";
     inputs.home-manager.follows = "home-manager";
   };

   firefox-addons = {
     url = "gitlab:rycee/nur-expressions";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   ```

   Pass `inputs` into `flake/nixos-configurations.nix`:

   ```nix
   nixosConfigurations = import ./flake/nixos-configurations.nix {
     inherit inputs home-manager nixpkgs;
   };
   ```

2. Update `flake/nixos-configurations.nix`.

   Accept `inputs`:

   ```nix
   {
     inputs,
     nixpkgs,
     home-manager,
     hostOverrides ? { },
     extraModules ? [ ],
     ...
   }:
   ```

   Pass it to NixOS modules:

   ```nix
   specialArgs = {
     inherit inputs host;
     inherit (host) hostname username stateVersion;
   };
   ```

3. Update `modules/nixos/home-manager.nix`.

   Accept `inputs` and pass it to Home Manager:

   ```nix
   { inputs, ... }:

   {
     home-manager = {
       useGlobalPkgs = true;
       useUserPackages = true;
       extraSpecialArgs = {
         inherit inputs;
       };

       users.r = import ../../users/r/home.nix;
     };
   }
   ```

4. Update `modules/nixos/browser.nix`.

   Add Zen Browser as a system package:

   ```nix
   { inputs, pkgs, ... }:

   let
     zenBrowser = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;
     zen = pkgs.writeShellScriptBin "zen" ''
       exec ${zenBrowser}/bin/zen-beta "$@"
     '';
   in
   {
     programs.firefox.enable = true;

     environment.systemPackages = [
       zenBrowser
       zen
     ];
   }
   ```

   Keep Firefox during the first rollout. After Zen is validated, a later
   cleanup can remove `programs.firefox.enable = true;` if the user wants Zen to
   be the only system browser.

   The selected Zen flake default package currently exposes `zen-beta`, not a
   plain `zen` command, so install the small wrapper above to provide `zen`.

5. Add `modules/home-manager/zen-browser.nix`.

   Use this implementation shape:

   ```nix
   { inputs, lib, pkgs, ... }:

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

       # Session restore and startup behavior.
       "browser.startup.page" = 3;
       "browser.sessionstore.restore_on_demand" = true;
       "browser.sessionstore.restore_pinned_tabs_on_demand" = true;
       "browser.sessionstore.resume_from_crash" = true;
       "zen.workspaces.continue-where-left-off" = true;
       "zen.urlbar.replace-newtab" = true;

       # Zen interface preferences.
       "zen.theme.content-element-separation" = 0;

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
           with (import inputs.firefox-addons { inherit pkgs; }).firefox-addons; [
             darkreader
             privacy-badger
             sponsorblock
             ublock-origin
             youtube-recommended-videos
           ];

         bookmarks = {
           force = true;
           settings = [
             {
               name = "YouTube";
               url = "https://youtube.com/";
               keyword = "y";
             }
             {
               name = "GitHub";
               url = "https://github.com/";
               keyword = "gh";
             }
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
   ```

   Keep the hardening preferences in a named local attrset so future changes are
   easy to review.

6. Update `modules/home-manager/programs.nix`.

   Import the new Zen module:

   ```nix
   {
     imports = [
       ./zen-browser.nix
       ./zsh.nix
     ];
   }
   ```

   Keep Git and Starship out of this import list. Their settings are
   live-linked from `dotfiles/` and should not be reintroduced as store-managed
   Home Manager modules.

7. Update lock file intentionally.

   Because this change adds flake inputs, `flake.lock` must be updated as an
   implementation step:

   ```console
   nix flake lock
   ```

   After this, validation commands must use `--no-write-lock-file` where
   applicable.

## Hardened LibreWolf-Style Baseline

Apply the hardening baseline as profile settings, not locked policies, unless a
specific setting requires policy control.

This is required because the user wants to manually change Zen settings later
and have those changes remembered. Locked policy preferences would prevent that.

The baseline should cover:

- Telemetry disabled.
- Firefox studies and experiments disabled.
- Normandy disabled.
- Crash reporting disabled.
- Pocket disabled.
- Sponsored suggestions disabled.
- Search suggestions disabled.
- Speculative network requests disabled.
- DNS prefetching disabled.
- Enhanced tracking protection enabled.
- Cryptomining and fingerprinting protection enabled.
- Resist fingerprinting enabled.
- Global Privacy Control enabled.
- Do Not Track enabled.
- HTTPS-only mode enabled.
- Mixed passive content blocking enabled.
- WebRTC local IP leak protections enabled.
- Previous windows and tabs restored on startup.
- Restored tabs loaded on demand, with the previous active tab expected to be
  selected.
- Zen workspace restore enabled.
- Zen's replacement of new-tab behavior with the URL bar prompt enabled.
- Zen content element separation set to `0`.
- Third-party and tracker cookie restrictions enabled.
- Address and credit card autofill disabled.
- Password saving disabled.
- DRM disabled by default.

Do not lock session/history-clearing behavior. The user specifically mentioned
that they may want to change whether Zen clears browsing history or closes
sessions after exit.

Compatibility warnings:

- `privacy.resistFingerprinting` can affect time zone behavior, canvas, window
  sizes, site compatibility, and extension behavior.
- DRM disabled by default can break Netflix, Spotify Web, and other protected
  media sites.
- Strict cookie and tracking protections can break login flows.
- WebRTC hardening can affect browser-based calls.
- Search and prefetch hardening can reduce convenience and perceived speed.

If any of these are too disruptive after testing, change the preference value in
the Nix config or remove that preference from the declarative baseline so Zen
can manage it normally.

## Extensions

Use packaged add-ons from rycee/NUR.

Starter extension:

- `ublock-origin`

Requested extension set:

- `darkreader`
- `privacy-badger`
- `sponsorblock`
- `youtube-recommended-videos`

Add more extensions by editing:

```nix
programs.zen-browser.profiles.default.extensions.packages =
  with (import inputs.firefox-addons { inherit pkgs; }).firefox-addons; [
    darkreader
    privacy-badger
    sponsorblock
    ublock-origin
    youtube-recommended-videos
  ];
```

`youtube-recommended-videos` is unfree (`unhook-eula`). Importing the add-ons
repo with this configuration's `pkgs` is required so the existing NixOS
`nixpkgs.config.allowUnfree = true` policy applies to that package.

Rules:

- Add an extension only if it exists in
  `(import inputs.firefox-addons { inherit pkgs; }).firefox-addons`.
- Do not silently switch to AMO `install_url` policies if a package is missing.
- If an extension is unavailable or unfree, document the limitation and ask the
  user before changing extension source strategy.
- Keep extension runtime state in the browser profile. Home Manager installs
  the extension package, but it does not preserve all extension runtime data by
  itself.
- Use `extensions.settings` only for extensions with stable, documented
  settings.

Useful lookup commands:

```console
nix flake show --no-write-lock-file gitlab:rycee/nur-expressions
nix eval --no-write-lock-file .#nixosConfigurations.conquest.pkgs.stdenv.hostPlatform.system
```

## Bookmarks

Use Home Manager profile bookmarks.

Initial pattern:

```nix
programs.zen-browser.profiles.default.bookmarks = {
  force = true;
  settings = [
    {
      name = "YouTube";
      url = "https://youtube.com/";
      keyword = "y";
    }
    {
      name = "GitHub";
      url = "https://github.com/";
      keyword = "gh";
    }
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
```

The Zen Browser Home Manager module requires `force = true` when bookmark
settings are declared. This means declarative bookmarks replace the managed
bookmark set for the profile. Export or copy any existing important bookmarks
before activating this configuration.

To add a bookmark:

```nix
{
  name = "Example";
  url = "https://example.com/";
}
```

To add an address-bar keyword bookmark:

```nix
{
  name = "Example";
  url = "https://example.com/";
  keyword = "ex";
}
```

To add a bookmark folder:

```nix
{
  name = "Development";
  bookmarks = [
    {
      name = "Nix Packages";
      url = "https://search.nixos.org/packages";
    }
  ];
}
```

## Validation

Because adding Zen requires new flake inputs, first update the lock file
intentionally:

```console
nix flake lock
```

Then validate from `/etc/nixos`:

```console
nix fmt -- --check .
statix check .
deadnix .
nix flake show --no-write-lock-file
nix flake check --no-build
sudo nixos-rebuild build --flake .#war
sudo nixos-rebuild build --flake .#conquest
```

If `statix` or `deadnix` is not available yet, report that limitation instead
of silently skipping it.

Do not run `nixos-rebuild switch`, reboot, or persistent activation without
explicit user approval.

After a successful build, temporary activation may be tested only after the user
requests it:

```console
sudo nixos-rebuild test --flake .#conquest
```

Manual checks after temporary activation:

```console
command -v zen
zen --version
```

Then confirm:

- Zen appears in the launcher.
- Zen opens under Wayland.
- A default Zen profile exists.
- uBlock Origin, and any other declared packaged extensions, are installed and
  enabled.
- Hardened defaults are visible in `about:config`.
- Manual Zen setting changes persist after closing and reopening the browser.
- Configured bookmarks appear.
- Declarative bookmarks replace the managed bookmark set because the module
  requires `force = true` when bookmark settings are declared.
- With one normal webpage tab open, quit Zen with `Ctrl+Q`, reopen it, and
  confirm that page is selected instead of the URL/search prompt.
- With three normal webpage tabs open and the third tab selected, quit Zen with
  `Ctrl+Q`, reopen it, and confirm the third tab is selected.
- Repeat the same test with the window close button. If `Ctrl+Q` works but the
  window close button restores the first tab, treat that as a Zen window-sync
  close-path limitation and prefer `Ctrl+Q` for session-preserving quits.

## Acceptance Criteria

The implementation is complete when:

- `flake.nix` contains Zen Browser and Firefox add-ons inputs.
- `flake/nixos-configurations.nix` passes `inputs` to NixOS modules.
- `modules/nixos/home-manager.nix` passes `inputs` to Home Manager modules.
- `modules/nixos/browser.nix` installs Zen Browser system-wide through
  `environment.systemPackages`.
- `modules/home-manager/zen-browser.nix` configures the Zen profile,
  hardening, extensions, and bookmarks.
- `modules/home-manager/programs.nix` imports the Zen Home Manager module.
- `flake.lock` is intentionally updated.
- `nix flake show --no-write-lock-file` succeeds.
- `nix flake check --no-build` succeeds.
- `sudo nixos-rebuild build --flake .#war` succeeds.
- `sudo nixos-rebuild build --flake .#conquest` succeeds.
- Zen can be launched with `zen`.
- Declared packaged extensions are present.
- Declared bookmarks are present.
- User-made setting changes inside Zen persist unless the setting is explicitly
  policy-controlled.

## Assumptions

- Use `github:0xc000022070/zen-browser-flake` because this repository's pinned
  nixpkgs currently does not provide `pkgs.zen-browser`.
- Use the Zen flake's default package for the first rollout.
- Use the Zen flake's default Home Manager module unless validation shows that
  `homeModules.beta` or another exported module is required.
- Use rycee/NUR Firefox add-ons as the only extension source for now, because
  the user requested packaged extensions.
- Keep Firefox as a temporary fallback until Zen has been built and manually
  tested.
- Use bookmark `force = true` because the Zen Browser Home Manager module
  requires it when bookmark settings are declared.
- Do not add Flatpak, Snap, AppImage, or imperative browser installation paths.
