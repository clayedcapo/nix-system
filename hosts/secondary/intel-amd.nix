# =============================================================================
# GPU CONFIGURATION: Intel (integrated) + AMD (discrete)
# =============================================================================
# Intel iGPU as primary display adapter
#
# This is a simpler setup than main host (AMD+NVIDIA):
#   - No PRIME offload needed (Intel handles most tasks)
#   - AMD GPU available for compute/gaming if needed
#   - Lower power consumption than discrete-only setup
#
# Unlike NVIDIA, AMD GPUs work well with open-source drivers (amdgpu)
# and don't require special Wayland workarounds.
{ config, pkgs, ... }:
{
  # ===========================================================================
  # KERNEL MODULES
  # ===========================================================================
  # Intel integrated + AMD discrete
  boot.initrd.kernelModules = [ "i915" "amdgpu" ];

  # ===========================================================================
  # VIDEO DRIVERS
  # ===========================================================================
  services.xserver.videoDrivers = [ "modesetting" "amdgpu" ];

  # ===========================================================================
  # GRAPHICS (OpenGL/Vulkan)
  # ===========================================================================
  # Intel GPU as primary
  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [
      intel-media-driver        # For Broadwell arch and newer
      libva-vdpau-driver
    ];
  };

  # ===========================================================================
  # PACKAGES
  # ===========================================================================
  environment.systemPackages = with pkgs; [
    nvtopPackages.intel # htop-like task monitor
    nvtopPackages.amd
  ];

  # ===========================================================================
  # ENVIRONMENT VARIABLES
  # ===========================================================================
  # Intel-specific settings
  environment.variables = {
    VDPAU_DRIVER = "va_gl";
  };

  # ===========================================================================
  # CPU MICROCODE
  # ===========================================================================
  # TODO: See if hardware-configuration.nix add it
  # hardware.cpu.intel.updateMicrocode = true;
}
