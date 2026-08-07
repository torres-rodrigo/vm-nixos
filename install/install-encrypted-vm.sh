set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: install-encrypted-vm [--dry-run] [--repo-root PATH]

Install the war VM with a Disko-managed LUKS2 + Btrfs layout.

Options:
  --dry-run         Generate temporary install files and print commands only.
  --repo-root PATH  Repository root to install from. Defaults to $PWD.
  -h, --help        Show this help.
USAGE
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

info() {
  printf '%s\n' "$*"
}

nix_string() {
  local value=$1

  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//\$\{/\\\$\{}
  printf '"%s"' "$value"
}

prompt_secret() {
  local prompt=$1
  local value

  printf '%s: ' "$prompt" >&2
  IFS= read -rs value
  printf '\n' >&2
  printf '%s' "$value"
}

validate_repo_root() {
  local value=$1

  [[ -f "$value/flake.nix" ]] || die "repo root does not contain flake.nix: $value"
  [[ -f "$value/install/disko-config.nix" ]] || die "repo root does not contain install/disko-config.nix: $value"
  [[ -f "$value/flake/nixos-configurations.nix" ]] || die "repo root does not contain flake/nixos-configurations.nix: $value"
  [[ "$value" != *[[:space:]]* ]] || die "repo root paths containing whitespace are not supported by this installer"
}

validate_disk() {
  local disk=$1
  local resolved
  local type

  [[ -e "$disk" ]] || die "target disk does not exist: $disk"
  resolved=$(readlink -f -- "$disk")
  [[ -b "$resolved" ]] || die "target is not a block device: $disk"

  type=$(lsblk -dnro TYPE -- "$resolved")
  [[ "$type" == "disk" ]] || die "target is not a whole disk: $disk"

  if lsblk -nrpo MOUNTPOINTS -- "$resolved" | grep -q '[^[:space:]]'; then
    die "target disk or one of its partitions is mounted; unmount it before installing"
  fi

  printf '%s' "$resolved"
}

select_disk() {
  local -a disks
  local selection
  local candidate

  mapfile -t disks < <(lsblk -dnpo PATH,TYPE | while read -r path type; do
    [[ "$type" == "disk" ]] || continue
    [[ "$path" != /dev/loop* ]] || continue
    [[ "$path" != /dev/sr* ]] || continue
    printf '%s\n' "$path"
  done)

  [[ ${#disks[@]} -gt 0 ]] || die "no whole disks were detected"

  printf '%s\n' "Available install targets:" >&2
  local i=1
  for candidate in "${disks[@]}"; do
    printf '  %s) ' "$i" >&2
    lsblk -dnro PATH,SIZE,MODEL,SERIAL,TRAN -- "$candidate" >&2
    i=$((i + 1))
  done

  while true; do
    printf 'Select target disk by number or path: ' >&2
    IFS= read -r selection

    if [[ "$selection" =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#disks[@]} )); then
      printf '%s' "${disks[$((selection - 1))]}"
      return
    fi

    if [[ -n "$selection" ]]; then
      printf '%s' "$selection"
      return
    fi

    printf '%s\n' "Selection is required." >&2
  done
}

write_install_files() {
  local work_dir=$1
  local repo_root=$2
  local disk=$3
  local disk_nix
  local repo_root_nix

  disk_nix=$(nix_string "$disk")
  repo_root_nix=$(nix_string "$repo_root")

  cat > "$work_dir/install-passwords.nix" <<'INSTALL_PASSWORDS'
{ lib, ... }:

let
  rootHash = lib.removeSuffix "\n" (builtins.readFile ./root-password-hash);
  userHash = lib.removeSuffix "\n" (builtins.readFile ./user-password-hash);
in
{
  users.mutableUsers = true;
  users.users.root.hashedPassword = rootHash;
  users.users.r.hashedPassword = userHash;
}
INSTALL_PASSWORDS

  cat > "$work_dir/install-disko.nix" <<INSTALL_DISKO
import (builtins.toPath (${repo_root_nix} + "/install/disko-config.nix")) {
  diskDevice = ${disk_nix};
}
INSTALL_DISKO

  cat > "$work_dir/flake.nix" <<TEMP_FLAKE
{
  description = "Temporary encrypted VM installer wrapper";

  inputs = {
    repo.url = "path:${repo_root}";
    nixpkgs.follows = "repo/nixpkgs";
    home-manager.follows = "repo/home-manager";
  };

  outputs = { nixpkgs, home-manager, repo, ... }:
    {
      nixosConfigurations = import (repo.outPath + "/flake/nixos-configurations.nix") {
        inherit nixpkgs home-manager;

        extraModules = [
          ./install-passwords.nix
        ];
      };
    };
}
TEMP_FLAKE
}

dry_run_commands() {
  local work_dir=$1
  local repo_root=$2

  cat <<COMMANDS
Dry run complete. The installer would run:

  install -m 0600 "$work_dir/luks-passphrase" /run/war-disko-luks-password
  disko --mode destroy,format,mount "$work_dir/install-disko.nix"
  nixos-generate-config --root /mnt --show-hardware-config > "$repo_root/hosts/war/hardware-configuration.nix"
  rsync -a --delete "$repo_root/" /mnt/etc/nixos/
  nixos-install --flake "$work_dir#war" --no-root-passwd
COMMANDS
}

copy_repo_to_target() {
  local repo_root=$1
  local target=/mnt/etc/nixos

  mkdir -p "$target"
  rsync -a --delete \
    --exclude '/result' \
    --exclude '/result-*' \
    --exclude '/.direnv' \
    --exclude '/.cache' \
    --exclude '/tmp' \
    "$repo_root/" "$target/"
}

main() {
  local dry_run=0
  local repo_root=$PWD

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        dry_run=1
        shift
        ;;
      --repo-root)
        [[ $# -ge 2 ]] || die "--repo-root requires a path"
        repo_root=$2
        shift 2
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        die "unknown argument: $1"
        ;;
    esac
  done

  repo_root=$(cd "$repo_root" && pwd -P)
  validate_repo_root "$repo_root"

  if [[ $dry_run -eq 0 && ${EUID:-$(id -u)} -ne 0 ]]; then
    die "run as root from the NixOS ISO, or use --dry-run"
  fi

  local disk
  local resolved_disk
  local secret
  local secret_repeat
  local final_confirm
  local work_dir

  disk=$(select_disk)
  resolved_disk=$(validate_disk "$disk")

  info ""
  info "Selected disk:"
  lsblk -o NAME,PATH,SIZE,MODEL,SERIAL,TYPE,MOUNTPOINTS -- "$resolved_disk"

  secret=$(prompt_secret "Shared LUKS/root/r password")
  [[ -n "$secret" ]] || die "password must not be empty"
  secret_repeat=$(prompt_secret "Repeat shared password")
  [[ "$secret" == "$secret_repeat" ]] || die "passwords do not match"
  secret_repeat=

  info ""
  info "This will permanently erase all data on:"
  info "  $resolved_disk"
  info ""
  info "The disk will be repartitioned, encrypted, formatted, mounted, and installed as NixOS."
  printf 'To continue, type the exact disk path: ' >&2
  IFS= read -r final_confirm
  [[ "$final_confirm" == "$resolved_disk" ]] || die "disk confirmation did not match; aborted"

  work_dir=$(mktemp -d -t war-encrypted-install.XXXXXX)
  chmod 0700 "$work_dir"

  cleanup() {
    rm -rf "$work_dir"
    rm -f /run/war-disko-luks-password 2>/dev/null || true
  }
  trap cleanup EXIT
  trap 'cleanup; exit 130' INT TERM

  umask 077
  printf '%s\n' "$secret" > "$work_dir/luks-passphrase"
  printf '%s\n' "$secret" | mkpasswd --method=yescrypt --stdin > "$work_dir/root-password-hash"
  printf '%s\n' "$secret" | mkpasswd --method=yescrypt --stdin > "$work_dir/user-password-hash"
  secret=
  chmod 0600 "$work_dir/luks-passphrase" "$work_dir/root-password-hash" "$work_dir/user-password-hash"

  write_install_files "$work_dir" "$repo_root" "$resolved_disk"

  if [[ $dry_run -eq 1 ]]; then
    dry_run_commands "$work_dir" "$repo_root"
    exit 0
  fi

  install -m 0600 "$work_dir/luks-passphrase" /run/war-disko-luks-password
  disko --mode destroy,format,mount "$work_dir/install-disko.nix"
  nixos-generate-config --root /mnt --show-hardware-config > "$repo_root/hosts/war/hardware-configuration.nix"
  copy_repo_to_target "$repo_root"
  nixos-install --flake "$work_dir#war" --no-root-passwd

  info ""
  info "Install complete. Reboot, unlock LUKS with the shared password, then log in as user r."
  info "The full Git checkout is already installed at /etc/nixos."
}

main "$@"
