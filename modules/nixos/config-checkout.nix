{ host, ... }:

{
  systemd.tmpfiles.rules = [
    "d /etc/nixos 0755 ${host.username} users - -"
    "Z /etc/nixos - ${host.username} users - -"
  ];
}
