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

The temporary install wrapper builds from `/mnt/etc/nixos` after the copy is
complete. This keeps the Nix flake input stable while `nixos-install` runs and
avoids stale `path:` input hashes from the live ISO checkout.
The installer also passes `--no-write-lock-file` to `nixos-install` so the
temporary wrapper flake is not modified while Nix is hashing and building it.

## Install Steps

1. Boot the VM from a current NixOS ISO in UEFI mode.

2. Connect networking in the live ISO environment.

3. Clone this repository into the live ISO environment:

   ```console
   git clone <repo-url> /tmp/nixos
   cd /tmp/nixos/vm-nixos
   ```

4. Confirm DNS and network access before starting the destructive install. The
   committed `flake.lock` pins exact inputs, but a fresh ISO still needs to
   fetch anything that is not already in its Nix store:

   ```console
   ping -c 3 github.com
   ping -c 3 cache.nixos.org
   nix --extra-experimental-features "nix-command flakes" flake check --no-build --no-write-lock-file
   ```

   If DNS fails, fix networking in the ISO first and rerun the checks. The
   installer runs this flake preflight before disk formatting and stops if
   required inputs cannot be fetched.

5. Optionally run a dry run first. This validates the repo shape, disk menu, and
   generated installer files without formatting or installing:

   ```console
   nix run .#install-encrypted-vm -- --dry-run
   ```

6. Run the real installer:

   ```console
   sudo nix run .#install-encrypted-vm
   sudo nix --extra-experimental-features "nix-command flakes" run .#install-encrypted-vm
   ```

7. Select the target disk from the numbered list.

8. Enter the shared LUKS, `root`, and user `r` password twice.

9. Confirm the destructive install by typing the exact selected disk path.

10. Wait for Disko, encrypted hardware configuration generation, repo copy, and
   `nixos-install` to complete.

11. Reboot and remove the ISO.

12. Unlock the disk with the shared password and log in as user `r` with the
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

Before reporting success, the installer also creates and validates a unique
`/mnt/etc/machine-id`. This is required by the system D-Bus broker during the
first userspace boot. It also normalizes the Btrfs subvolume root permissions
and verifies that an unprivileged target user can execute a program from the
installed Nix store.

After LUKS unlock, greetd starts Mango through UWSM as user `r` with an
automatic `initial_session`. The `tuigreet` session remains configured as the
manual fallback if Mango exits or the initial session is not used. Both paths
use the `war-mango-session` wrapper so Mango startup failures are written to
the journal and `/home/r/.local/state/war/mango-session.log`. The wrapper
generates the UWSM units, binds the UWSM session to the greetd-owned wrapper
process, then waits on `wayland-wm@mango.service` so greetd does not return to
the greeter while Mango is still managed by user systemd. For the GNOME Boxes
VM path, the wrapper also applies conservative wlroots fallbacks:
`WLR_RENDERER=pixman`, `WLR_NO_HARDWARE_CURSORS=1`, and
`WLR_DRM_NO_ATOMIC=1`.

## First Boot Debugging

The expected boot handoff is:

1. Plymouth shows the LUKS unlock prompt.
2. After the password is accepted, Plymouth exits.
3. greetd starts user `r` automatically.
4. Mango starts through UWSM using `/home/r/.config/mango/config.conf`.

If Plymouth stays on a full progress bar, press `Esc` to show the boot log. If a
shell is available on another TTY, switch with `Ctrl+Alt+F2` and inspect:

```console
journalctl -b -t war-mango-session --no-pager
journalctl -b -u greetd --no-pager
journalctl --user -b -u 'wayland-wm@mango.service' --no-pager
journalctl --user -b -u 'wayland-session-envelope@mango.target' --no-pager
journalctl -b | rg -i "qxl|virtio_gpu|drm|renderD|mango|wlroots"
journalctl -b -u plymouth-quit -u plymouth-quit-wait --no-pager
journalctl -b -u dbus --no-pager
systemctl status greetd plymouth-quit plymouth-quit-wait dbus
systemctl --user status wayland-wm@mango.service wayland-session-envelope@mango.target
cat /home/r/.local/state/war/mango-session.log
```

For GNOME Boxes testing, verify the VM is not still using QXL graphics. The
current logs have shown `Initialized qxl`, which is a weak target for
Mango/wlroots, especially when `/dev/dri` has no `renderD*` node. The pixman
fallback is intended to keep the VM usable for bring-up. For better long-term
testing, use `virt-manager` or the libvirt XML for the Boxes VM to change the
video model from QXL to Virtio, enable 3D/OpenGL acceleration if available,
then reboot and confirm the guest journal no longer reports QXL.

The original boot loop was caused by the installer applying `umask 077` while
Disko created the Btrfs subvolumes. This left `/nix` with mode `0700` even
though files below `/nix/store` had executable permissions. Unprivileged
services could not traverse `/nix`, so systemd reported `status=203/EXEC` and
`Permission denied` for `systemd-timesyncd`, `systemd-resolved`, and the D-Bus
broker child. The network services restarted repeatedly and socket-activated
D-Bus each time, preventing `basic.target`, TTY logins, greetd, and Mango from
being reached.

The systemd-boot menu remains visible for five seconds. Select
`NixOS (boot-debug)` to boot without Plymouth or greetd and stop
at a normal console login under `multi-user.target`. This entry is intended for
diagnostics; the default entry still uses the graphical boot and Mango login
path.

To repair a VM installed before the subvolume permission fix, boot the NixOS
ISO, unlock the encrypted partition, and mount every subvolume except `/boot`.
Adjust the encrypted partition path if the VM disk is not `/dev/sda`:

```console
sudo cryptsetup open /dev/sda2 cryptroot
sudo mount -o subvol=root /dev/mapper/cryptroot /mnt
sudo mkdir -p /mnt/home /mnt/nix /mnt/var
sudo mount -o subvol=home /dev/mapper/cryptroot /mnt/home
sudo mount -o subvol=nix /dev/mapper/cryptroot /mnt/nix
sudo mount -o subvol=var /dev/mapper/cryptroot /mnt/var
sudo mkdir -p /mnt/var/log
sudo mount -o subvol=log /dev/mapper/cryptroot /mnt/var/log

sudo chmod 0755 /mnt /mnt/home /mnt/nix /mnt/var /mnt/var/log
sudo -u nobody test -x /mnt/nix/store

sudo umount /mnt/var/log /mnt/var /mnt/nix /mnt/home /mnt
sudo cryptsetup close cryptroot
sudo reboot
```

The `test` command must return without output and with exit status zero. Do not
change `/boot`; its restrictive FAT mount permissions are intentional.
