{ ... }:

{
  users.mutableUsers = true;

  users.users.r = {
    isNormalUser = true;
    uid = 1000;
    description = "r";
    home = "/home/r";
    extraGroups = [
      "audio"
      "networkmanager"
      "render"
      "seat"
      "video"
      "wheel"
    ];
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };
}
