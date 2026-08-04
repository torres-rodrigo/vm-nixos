{ ... }:

{
  networking.networkmanager.dns = "systemd-resolved";

  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      DNSOverTLS = "opportunistic";
      FallbackDNS = [
        "9.9.9.9"
        "149.112.112.112"
        "1.1.1.1"
        "1.0.0.1"
      ];
    };
  };
}
