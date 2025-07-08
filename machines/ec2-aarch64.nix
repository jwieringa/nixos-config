# EC2 ARM64 configuration for headless server deployment
{ config, pkgs, lib, currentSystem, currentSystemName, ... }:

{
  imports = [
    ./hardware/ec2-aarch64.nix
    ./vm-shared.nix
  ];

  # Setup qemu so we can run x86_64 binaries if needed
  boot.binfmt.emulatedSystems = ["x86_64-linux"];
  
  # Use stable kernel for better EC2 compatibility
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

  # EC2 uses eth0 interface typically
  networking.interfaces.eth0.useDHCP = true;

  # Allow unfree packages and unsupported system
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;

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