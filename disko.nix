# =============================================================================
# DISKO: DECLARATIVE DISK PARTITIONING
# =============================================================================
# This file defines the disk layout for all hosts
# Disko handles partitioning during installation and generates mount configuration
#
# Layout: GPT with two partitions
#   1. ESP (512M) - EFI System Partition for bootloader
#   2. LUKS (rest) - Encrypted root partition with ext4
#
# Host-specific settings (device path, TRIM support) are configured below
{ hostname, ... }:
let
  # ===========================================================================
  # HOST-SPECIFIC DISK CONFIGURATION
  # ===========================================================================
  # Each host defines:
  #   - device: Block device path for the primary disk
  #   - allowDiscards: Enable TRIM passthrough for SSDs (slight security tradeoff)
  diskConfig = {
    main = {
      device = "/dev/nvme0n1";
      allowDiscards = true;   # NVMe benefits from TRIM
    };
    secondary = {
      device = "/dev/sda";
      allowDiscards = false;  # HDD - no TRIM benefit
    };
  }.${hostname};

in
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = diskConfig.device;
        content = {
          type = "gpt";
          partitions = {
            # -----------------------------------------------------------------
            # ESP: EFI System Partition
            # -----------------------------------------------------------------
            # Houses the bootloader (systemd-boot)
            # 512M is sufficient for multiple kernel generations
            ESP = {
              priority = 1;
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" "umask=0077" ];
              };
            };

            # -----------------------------------------------------------------
            # LUKS: Encrypted Root Partition
            # -----------------------------------------------------------------
            # Full disk encryption with LUKS2
            # Password will be prompted during installation
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                settings = {
                  # TRIM passthrough - host-specific (SSD vs HDD)
                  allowDiscards = diskConfig.allowDiscards;
                  # Performance optimization for modern multi-core CPUs
                  # Avoids context switching overhead during (en|de)cryption
                  bypassWorkqueues = true;
                  # NOTE: Both options above are repeated in host specific system configs, see note on that below
                };
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };
    };
  };
}
# =============================================================================
# USAGE
# =============================================================================
#
# INSTALLATION (from live ISO):
#   sudo nix --experimental-features "nix-command flakes" run \
#     github:nix-community/disko -- --mode disko --flake .#<hostname>
#
# This will:
#   1. Partition the disk according to this configuration
#   2. Format partitions (vfat for ESP, ext4 for root)
#   3. Set up LUKS encryption (prompts for password)
#   4. Mount everything to /mnt
#
# After disko completes, proceed with:
#   sudo nixos-install --flake .#<hostname>
#
# =============================================================================
# NOTES
# =============================================================================
#
# - The LUKS device name "cryptroot" must match boot.initrd.luks.devices
#   in the host's default.nix for runtime settings
# - Runtime LUKS options (allowDiscards, bypassWorkqueues) are also set
#   in hosts/*/default.nix - both locations are needed:
#     * disko.nix: Initial device setup during installation
#     * default.nix: Runtime behavior after boot
#
