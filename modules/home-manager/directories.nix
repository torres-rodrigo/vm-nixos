{ ... }:

{
  systemd.user.tmpfiles.rules = [
    "d %h/.cache 0700 - - -"
    "d %h/.cache/dotnet 0700 - - -"
    "d %h/.cache/go 0700 - - -"
    "d %h/.cache/go/mod 0700 - - -"
    "d %h/.cache/nuget 0700 - - -"
    "d %h/.cache/zig 0700 - - -"
    "d %h/.cache/zsh 0700 - - -"
    "d %h/.config 0700 - - -"
    "d %h/.config/dotnet 0700 - - -"
    "d %h/.local 0700 - - -"
    "d %h/.local/bin 0700 - - -"
    "d %h/.local/share 0700 - - -"
    "d %h/.local/share/cargo 0700 - - -"
    "d %h/.local/share/cargo/bin 0700 - - -"
    "d %h/.local/share/go 0700 - - -"
    "d %h/.local/share/go/bin 0700 - - -"
    "d %h/.local/share/icons 0700 - - -"
    "d %h/.local/share/rustup 0700 - - -"
    "d %h/.local/share/src 0700 - - -"
    "d %h/.local/share/zig 0700 - - -"
    "d %h/.local/state 0700 - - -"
    "d %h/.local/state/zsh 0700 - - -"
    "f %h/.local/state/zsh/.zsh_history 0600 - - -"
  ];
}
