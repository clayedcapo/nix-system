{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  # SSD specific. Allows TRIM through encryptions layer, but
  # WARN: slightly reduces security (blocks could be identified in theory)
  boot.initrd.luks.devices.cryptroot = {
    allowDiscards = true;
    # Optimization that allows (en,de)cryption to happen on a single core, so
    # no performance hits with context switching
    bypassWorkqueues = true;
  };

  # WARN: This is experimental. On any RAM problems consider to change.
  boot.tmp = {
    useZram = true;
    zramSettings.zram-size = "ram * 0.14";
  };

  # Those two kernel parameters fine tune swap space for zram
  boot.kernel.sysctl = {
    "vm.swappiness" = 150;
    # Consider adjusting this value (higher values - more reclaims of cached memory).
    "vm.vfs_cache_pressure" = 50;
  };

  zramSwap.memoryPercent = 40;

  # Periodic TRIM in the background
  services.fstrim.enable = true;
}
