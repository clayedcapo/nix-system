{ config, pkgs, ... }:
{
  # Intel integrated + AMD discrete
  boot.initrd.kernelModules = [ "i915" "amdgpu" ];

  services.xserver.videoDrivers = [ "modesetting" "amdgpu" ];

  # Intel GPU as primary
  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [
      vaapiIntel        # For older Intel GPUs
      vaapiVdpau
      amdvlk
    ];

    extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk
    ];
  };

  # Intel-specific settings
  environment.variables = {
    VDPAU_DRIVER = "va_gl";
  };

  # See if hardware-configuration.nix add it
  # hardware.cpu.intel.updateMicrocode = true;

  # No special Wayland workarounds needed for Intel
  # (no WLR_NO_HARDWARE_CURSORS like with NVIDIA)
}
