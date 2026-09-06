{ diskDevice, passwordFile }:

{
    disko.devices.disk.main = {
        type = "disk";
        device = diskDevice;

        content = {
            type = "gpt";

            partitions = {
                ESP = {
                    size = "1G";
                    type = "EF00";

                    content = {
                        type = "filesystem";
                        format = "vfat";
                        mountpoint = "/boot";
                        mountOptions = [ "unmask=0077" ];
                    };
                };
            };

            luks = {
                size = "100%";

                content = {
                    type = "luks";
                    name = "cryptroot";
                    passwordFile = passwordFile;

                    extraFormatArgs = [
                    "--type"
                    "luks2"
                    "--pbkdf"
                    "argon2id"
                    ];

                    extraOpenArgs = [
                        "--allow-discards"
                    ];

                    content = {
                        type = "btrfs";
                        extraArgs = [ "-f" ];

                        subvolumes = {
                            "/root" = {
                                mountpoint = "/";
                                mountOptions = [
                                    "compress=zstd"
                                    "noatime"
                                ];
                            };

                            "/home" = {
                                mountpoint = "/home";
                                mountOptions = [
                                    "compress=zstd"
                                    "noatime"
                                ];
                            };
                        };
                    };
                };
            };
        };
    };
}
