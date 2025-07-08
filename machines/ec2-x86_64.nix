# EC2 x86_64 configuration for headless server deployment
{ config, pkgs, lib, currentSystem, currentSystemName, ... }:

{
  imports = [
    ./hardware/ec2-x86_64.nix
    ./vm-shared.nix
  ];

  # Use stable kernel for better EC2 compatibility
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

  # Override boot configuration to use GRUB instead of systemd-boot
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = lib.mkForce true;
  boot.loader.grub.device = "/dev/nvme0n1";
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  # EC2 uses eth0 interface typically
  networking.interfaces.eth0.useDHCP = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable cloud-init for EC2 metadata support
  services.cloud-init.enable = true;

  # EC2 instances need this for proper boot
  boot.initrd.availableKernelModules = [ "nvme" "xen_blkfront" ];
  boot.initrd.kernelModules = [ "nvme" ];

  # Override vm-shared.nix settings for EC2 security
  networking.firewall.enable = lib.mkForce true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  
  # Disable desktop environment completely for EC2
  services.xserver.enable = lib.mkForce false;
  services.xserver.desktopManager.gnome.enable = lib.mkForce false;
  services.xserver.displayManager.gdm.enable = lib.mkForce false;
  
  # SSH security hardening
  services.openssh.settings.PasswordAuthentication = lib.mkForce false;
  services.openssh.settings.X11Forwarding = lib.mkForce false;
  services.openssh.settings.PermitRootLogin = lib.mkForce "no";
}