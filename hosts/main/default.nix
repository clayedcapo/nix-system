# =============================================================================
# HOST: main
# =============================================================================
# Main laptop: AMD CPU + NVIDIA GPU (16GB RAM)
# Hardware-specific configuration for performance-oriented setup
{ config, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  # ===========================================================================
  # DISK ENCRYPTION (LUKS)
  # ===========================================================================
  # Disk encryption itself specified in disko config
  #
  # SSD specific. Allows TRIM through encryptions layer at runtime, but
  # WARN: slightly reduces security (blocks could be identified in theory)
  boot.initrd.luks.devices.cryptroot = {
    allowDiscards = true;
    # Optimization that allows (en,de)cryption to happen on a single core, so no performance hits from context switching
    bypassWorkqueues = true;
  };

  # ===========================================================================
  # TEMPORARY FILES
  # ===========================================================================
  #
  # Places `/tmp` on zram device, consumes RAM, can lead to build failures
  # WARN: This is experimental. On any RAM problems consider to change
  boot.tmp = {
    useZram = true;
    zramSettings.zram-size = "ram * 0.14";
  };

  # ===========================================================================
  # MEMORY MANAGEMENT
  # ===========================================================================
  #
  # Those kernel parameters fine tune swap space for zram
  boot.kernel.sysctl = {
    # Defines how eagerly to swap pages, should be high for zram setup in general
    "vm.swappiness" = 150;
    # Consider adjusting this value (higher values - more reclaims of cached memory)
    "vm.vfs_cache_pressure" = 50;
    # Controls aggressiveness of memory reclaim (default: 15000)
    # Setting to 0 disables watermark boost, preventing premature memory reclamation after hitting `min` watermark
    # in memory zone. This allows fuller memory utilization before the kernel starts reclaiming pages (standard
    # behavior leads to a "boost" in watermark values after `min` watermark, which triggers aggressive reclaims for
    # free memory reserves build up).
    "vm.watermark_boost_factor" = 0;
    # Controls kswapd wakeup frequency (range: 1-1000, default: 10) by scaling gaps between watermarks (formula:
    # gap = (factor / 10000) x total_memory).
    # A higher value triggers background memory reclamation (not direct one) earlier.
    # Value 125 = 1.25% of memory as watermark gap, balancing memory proactively to prevent
    # sudden swap storms at high swappiness values.
    "vm.watermark_scale_factor" = 125;
    # Controls swap readahead (range: 0-6, default: 3) 0 means read only 1 page (2^0) at a time, disabling readahead.
    # For low-latency devices like zram, readahead hurts performance by fetching unnecessary data.
    "vm.page-cluster" = 0;
  };

  zramSwap.memoryPercent = 40;

  # ===========================================================================
  # PACKAGES
  # ===========================================================================
  environment.systemPackages = with pkgs; [
    nvme-cli
    nvme-rs # NVMe drive health monitoring utility
  ];

  # ===========================================================================
  # SSD MAINTENANCE
  # ===========================================================================
  #
  # Periodic TRIM in the background
  services.fstrim.enable = true;

  # ===========================================================================
  # MISCELLANEOUS
  # ===========================================================================
  #
  # KMSCON as the virtual console instead of gettys.
  # KMSCON is a kms/dri-based userspace virtual terminal implementation.
  # It supports a richer feature set than the standard linux console VT,
  # including full unicode support, and when the video card supports DRM should be much faster.
  services.kmscon = {
    enable = true;
    fonts = [
      {
        name = "AporeticSerifMonoNerdFont";
        package = inputs.aporetic-nerd-font.packages.${pkgs.system}.default;
      }
      {
        name = "JetBrainsMono Nerd Font";
        package = pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; };
      }
    ];
    extraOptions = "--term xterm-256color";
    extraConfig = "font-size=13";
    # Whether to use 3D hardware acceleration to render the console.
    hwRender = true;
    # NOTE: Maybe keep tty1 as traditional VT for emergency recovery
    # extraConfig = ''
    #   xkb-layout=us
    # '';
  };
}
