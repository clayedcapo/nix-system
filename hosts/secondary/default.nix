# =============================================================================
# HOST: secondary
# =============================================================================
# Secondary laptop: Intel CPU + AMD GPU (4GB RAM)
# Hardware-specific configuration optimized for limited resources.

{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  # ===========================================================================
  # TEMPORARY FILES
  # ===========================================================================

  # Use disk instead of RAM for /tmp (conserve memory on 4GB system)
  boot.tmp.cleanOnBoot = true;

  # ===========================================================================
  # DISK ENCRYPTION (LUKS)
  # ===========================================================================

  # Optimization that allows (en,de)cryption to happen on a single core, so
  # no performance hits with context switching
  boot.initrd.luks.devices.cryptroot.bypassWorkqueues = true;

  # ===========================================================================
  # MEMORY MANAGEMENT
  # ===========================================================================

  # Those two kernel parameters fine tune swap space for zram
  boot.kernel.sysctl = {
    "vm.swappiness" = 100;
    # Consider adjusting this value (higher values - more reclaims of cached memory).
    "vm.vfs_cache_pressure" = 100;
  };

  # Lower zram percentage due to limited RAM
  zramSwap.memoryPercent = 20;
}
