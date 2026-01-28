{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.tmp.cleanOnBoot = true;

  # Optimization that allows (en,de)cryption to happen on a single core, so
  # no performance hits with context switching
  boot.initrd.luks.devices.cryptroot.bypassWorkqueues = true;

  # Those two kernel parameters fine tune swap space for zram
  boot.kernel.sysctl = {
    "vm.swappiness" = 100;
    # Consider adjusting this value (higher values - more reclaims of cached memory).
    "vm.vfs_cache_pressure" = 100;
  };

  zramSwap.memoryPercent = 20;
}
