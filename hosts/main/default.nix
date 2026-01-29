# =============================================================================
# HOST: main
# =============================================================================
# Main laptop: AMD CPU + NVIDIA GPU (16GB RAM)
# Hardware-specific configuration for performance-oriented setup.

{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  # ===========================================================================
  # DISK ENCRYPTION (LUKS)
  # ===========================================================================

  # SSD specific. Allows TRIM through encryptions layer, but
  # WARN: slightly reduces security (blocks could be identified in theory)
  boot.initrd.luks.devices.cryptroot = {
    allowDiscards = true;
    # Optimization that allows (en,de)cryption to happen on a single core, so
    # no performance hits with context switching
    bypassWorkqueues = true;
  };

  # ===========================================================================
  # TEMPORARY FILES
  # ===========================================================================

  # WARN: This is experimental. On any RAM problems consider to change.
  boot.tmp = {
    useZram = true;
    zramSettings.zram-size = "ram * 0.14";
  };

  # ===========================================================================
  # MEMORY MANAGEMENT
  # ===========================================================================

  # Those two kernel parameters fine tune swap space for zram
  boot.kernel.sysctl = {
    "vm.swappiness" = 150;
    # Consider adjusting this value (higher values - more reclaims of cached memory).
    "vm.vfs_cache_pressure" = 50;
  };

  zramSwap.memoryPercent = 40;

  # ===========================================================================
  # SSD MAINTENANCE
  # ===========================================================================

  # Periodic TRIM in the background
  services.fstrim.enable = true;
}
