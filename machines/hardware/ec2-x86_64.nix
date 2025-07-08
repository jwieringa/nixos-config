# EC2 x86_64 hardware configuration
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/amazon-image.nix")
  ];

  boot.initrd.availableKernelModules = [ "nvme" "xen_blkfront" "xen_netfront" ];
  boot.initrd.kernelModules = [ "nvme" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # EC2 instances typically use NVMe storage
  fileSystems."/" =
    { device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
    };

  swapDevices = [ ];

  # Enable EC2 instance metadata service
  networking.useDHCP = lib.mkDefault true;
  
  # Disable predictable network interface names (EC2 uses eth0)
  networking.usePredictableInterfaceNames = false;
}