# VMware Fusion NixOS Disk Expansion Tutorial

This tutorial covers expanding the primary partition on your NixOS VMware Fusion VM after the virtual disk has been expanded in VMware.

## Current System Layout

Based on your current system:

- **Disk**: `/dev/nvme0n1`
- **Primary partition**: `/dev/nvme0n1p1`
- **Swap partition**: `/dev/nvme0n1p2`
- **Boot partition**: `/dev/nvme0n1p3` (511M, FAT32, mounted at `/boot`)

## Prerequisites

⚠️ **CRITICAL SAFETY WARNINGS**:

1. **Backup your VM** before proceeding - create a snapshot or full backup
2. This process will modify partition tables and filesystems
3. Data loss is possible if commands are executed incorrectly
4. Test in a snapshot first if possible

## Step-by-Step Expansion Process

### 1. Verify the expanded disk is recognized

```bash
# Check current disk size
sudo parted /dev/nvme0n1 print

# Verify filesystem usage
df -h /
```

### 2. Delete existing swap to make room for expansion

```bash
# Disable swap
sudo swapoff /dev/nvme0n1p2

# Check current partition layout
sudo parted /dev/nvme0n1 print

# Remove swap partition (partition 2)
sudo parted /dev/nvme0n1 rm 2
```

### 3. Expand the root partition using parted

```bash
# Extend root partition to use additional space
sudo parted /dev/nvme0n1 resizepart 1 INSERT_END_IN_GB (example: 200GB)
```

### 4. Verify the partition changes

```bash
# Check the new partition layout
sudo parted /dev/nvme0n1 print
```

### 5. Expand the filesystem

```bash
# Check filesystem before expansion
sudo fsck -f /dev/nvme0n1p1

# Expand the ext4 filesystem to use the full partition
sudo resize2fs /dev/nvme0n1p1

# Verify the expansion
df -h /
```

### 6. Create new swap space at the end of the disk

```bash
# Create new swap partition using remaining space
sudo parted /dev/nvme0n1 mkpart primary linux-swap INSERT_END_FROM_ROOT_PARTITION 100%

# Set the swap flag on the new partition
sudo parted /dev/nvme0n1 set 2 swap on
```

### 7. Format and enable the new swap

```bash
# Format the new swap partition
sudo mkswap /dev/nvme0n1p2

# Enable the swap
sudo swapon /dev/nvme0n1p2

# Verify swap is working
free -h
```

## Update NixOS Configuration

Update your NixOS configuration to use the new swap partition:

```bash
# Find the new swap UUID
sudo blkid /dev/nvme0n1p2

# Edit your NixOS configuration
sudo nano /etc/nixos/configuration.nix
```

Update the swap configuration:

```nix
swapDevices = [
  { device = "/dev/disk/by-uuid/YOUR-NEW-SWAP-UUID"; }
];
```

Then rebuild:

```bash
sudo nixos-rebuild switch
```

