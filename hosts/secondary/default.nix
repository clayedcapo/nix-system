# =============================================================================
# HOST: secondary
# =============================================================================
# Secondary laptop: Intel CPU + AMD GPU (4GB RAM)
# Hardware-specific configuration optimized for limited resources
#
# Key differences from main host:
#   - Lower zram percentage (20% vs 40%) - conserves limited RAM
#   - No /tmp on zram - uses disk to preserve memory
#   - Higher watermark_scale_factor (2% vs 1.25%) - earlier memory reclaim
#   - No SSD TRIM - HDD doesn't benefit from it
{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  # ===========================================================================
  # TEMPORARY FILES
  # ===========================================================================
  # Use disk instead of RAM for /tmp (conserve memory on 4GB system)
  # Unlike main host which uses zram for /tmp
  boot.tmp.cleanOnBoot = true;

  # ===========================================================================
  # DISK ENCRYPTION (LUKS)
  # ===========================================================================
  # Disk encryption itself specified in disko config
  #
  # NOTE: No allowDiscards here (HDD doesn't benefit from TRIM)
  #
  # Optimization that allows (en,de)cryption to happen on a single core, so
  # no performance hits with context switching
  boot.initrd.luks.devices.cryptroot.bypassWorkqueues = true;

  # ===========================================================================
  # MEMORY MANAGEMENT
  # ===========================================================================
  # Those two kernel parameters fine tune swap space for zram
  boot.kernel.sysctl = {
    # Defines how eagerly to swap pages, should be high for zram setup in general
    "vm.swappiness" = 100;
    # Consider adjusting this value (higher values - more reclaims of cached memory).
    "vm.vfs_cache_pressure" = 100;
    # Controls aggressiveness of memory reclaim (default: 15000)
    # Setting to 0 disables watermark boost, preventing premature memory reclamation after hitting `min` watermark
    # in memory zone. This allows fuller memory utilization before the kernel starts reclaiming pages (standard
    # behavior leads to a "boost" in watermark values after `min` watermark, which triggers aggressive reclaims for
    # free memory reserves build up).
    "vm.watermark_boost_factor" = 0;
    # Controls kswapd wakeup frequency (range: 1-1000, default: 10) by scaling gaps between watermarks (formula:
    # gap = (factor / 10000) x total_memory).
    # A higher value triggers background memory reclamation (not direct one) earlier.
    # Value 200 = 2% of memory as watermark gap. Higher than main machine (1.25%) due to limited RAM,
    # preventing OOM situations by starting reclaim earlier.
    "vm.watermark_scale_factor" = 200;
    # Controls swap readahead (range: 0-6, default: 3) 0 means read only 1 page (2^0) at a time, disabling readahead.
    # For low-latency devices like zram, readahead hurts performance by fetching unnecessary data.
    "vm.page-cluster" = 0;
  };

  # Lower zram percentage due to limited RAM
  zramSwap.memoryPercent = 20;
}
