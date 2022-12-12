{ pkgs ? import <nixpkgs> {}
, systemName ? "vm-intel"
}:

pkgs.mkShell {
  buildInputs = [
    pkgs.nixUnstable
    pkgs.parted
  ];
  shellHook = ''
    set -e -u -o pipefail
    parted /dev/nvme0n1 -- mklabel gpt
    parted /dev/nvme0n1 -- mkpart primary 512MiB -8GiB
    parted /dev/nvme0n1 -- mkpart primary linux-swap -8GiB 100%
    parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
    parted /dev/nvme0n1 -- set 3 esp on
    sleep 1
    mkfs.ext4 -L nixos /dev/nvme0n1p1
    mkswap -L swap /dev/nvme0n1p2
    mkfs.fat -F 32 -n boot /dev/nvme0n1p3
    sleep 1
    mount /dev/disk/by-label/nixos /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/boot /mnt/boot
    # generates hadware configurations
    nixos-generate-config --root /mnt
    NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-install --flake "/nix-config#${systemName}" --no-root-passwd -v --root /mnt
  '';
}
