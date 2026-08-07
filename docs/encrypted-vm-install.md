# Encrypted VM Install

This workflow performs a fresh encrypted install of the `war` VM from a NixOS
ISO. It is destructive: the selected target disk is repartitioned, encrypted,
formatted, and installed from scratch.

The installer uses one bootstrap password for all three initial credentials:

- LUKS disk unlock
- `root`
- user `r`

The password is used during installation only. It is not committed to the
repository. After the first successful boot, rotate any passwords you want to
separate.

## What The Installer Creates

The Disko layout is defined in `install/disko-config.nix`:

- UEFI GPT partition table
- `1G` EFI system partition mounted at `/boot`
- LUKS2 encrypted root container named `cryptroot`
- Btrfs filesystem inside LUKS
- Btrfs subvolumes for `/`, `/home`, `/nix`, `/var`, and `/var/log`

During install, the checked-out repository is copied to `/mnt/etc/nixos` with
`.git` included. After reboot, the full Git checkout is available at
`/etc/nixos`, including history, branches, and remotes. You do not need to clone
the repo again inside the installed VM.

## Install Steps

1. Boot the VM from a current NixOS ISO in UEFI mode.

2. Connect networking in the live ISO environment.

3. Clone this repository into the live ISO environment:

   ```console
   git clone <repo-url> /tmp/nixos
   cd /tmp/nixos/vm-nixos
   ```

4. Optionally run a dry run first. This validates the repo shape, disk menu, and
   generated installer files without formatting or installing:

   ```console
   nix run .#install-encrypted-vm -- --dry-run
   ```

5. Run the real installer:

   ```console
   sudo nix run .#install-encrypted-vm
   ```

6. Select the target disk from the numbered list.

7. Enter the shared LUKS, `root`, and user `r` password twice.

8. Confirm the destructive install by typing the exact selected disk path.

9. Wait for Disko, encrypted hardware configuration generation, repo copy, and
   `nixos-install` to complete.

10. Reboot and remove the ISO.

11. Unlock the disk with the shared password and log in as user `r` with the
    same password.

## After Reboot

The installed checkout is already in place:

```console
cd /etc/nixos
git status
sudo nixos-rebuild switch --flake .#war
```

To bring in later changes:

```console
cd /etc/nixos
git pull
sudo nixos-rebuild switch --flake .#war
```

Because `/etc/nixos/.git` is preserved, normal Git workflows continue from the
installed system.

## Validation

Before testing a real install, validate the flake from the development checkout:

```console
nix flake show --no-write-lock-file
nix flake check --no-build
```

After the encrypted install and first boot, verify:

```console
lsblk -f
findmnt /
findmnt /home
findmnt /nix
findmnt /var
findmnt /var/log
cd /etc/nixos
git status
sudo nixos-rebuild build --flake .#war
```

The installer writes the encrypted hardware configuration explicitly after
Disko finishes. Do not replace it with plain `nixos-generate-config` output:
the file must contain `boot.initrd.luks.devices.cryptroot` and Btrfs subvolume
mounts for `/`, `/home`, `/nix`, `/var`, and `/var/log`.

The expected result is an unlocked `cryptroot` device with the Btrfs subvolumes
mounted, a working user `r`, and a full Git checkout at `/etc/nixos`.

For the current validation pass, greetd opens `tuigreet` first. Log in as user
`r`; the configured command starts Mango through UWSM. Mango autologin can be
restored after encrypted boot and the compositor path are both reliable.
