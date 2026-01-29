# =============================================================================
# GPU CONFIGURATION: AMD (integrated) + NVIDIA (discrete)
# =============================================================================
# PRIME offload configuration for hybrid graphics.
# AMD iGPU is primary (power saving), NVIDIA dGPU on demand (performance).

{ config, pkgs, ... }:
{
  # ===========================================================================
  # KERNEL MODULES
  # ===========================================================================

  boot.initrd.kernelModules = [ "amdgpu" ];

  # ===========================================================================
  # VIDEO DRIVERS
  # ===========================================================================

  services.xserver.videoDrivers = [ "nvidia" ];

  # ===========================================================================
  # NVIDIA CONFIGURATION
  # ===========================================================================

  hardware.nvidia = {
    # Use open-source kernel modules (for RTX 20 series and newer)
    open = true;

    # GUI configuration tool
    nvidiaSettings = true;

    # Specific driver package to use
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # -------------------------------------------------------------------------
    # PRIME Offload
    # -------------------------------------------------------------------------
    prime = {
      offload = {
        enable = true;
        # Enables commands like `prime` for manual offloading
        enableOffloadCmd = true;
      };

      # Find with: lspci | grep -E "VGA|3D"
      amdgpuBusId = "PCI:5:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    # -------------------------------------------------------------------------
    # Power Management
    # -------------------------------------------------------------------------
    powerManagement.enable = true;

    # NOTE: experimental, not sure it will work on my machine
    # Enables dynamic power shifts between cpu and gpu as optimization
    dynamicBoost.enable = true;
  };

  # ===========================================================================
  # GRAPHICS (OpenGL/Vulkan)
  # ===========================================================================

  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [
      amdvlk
      rocm-opencl-icd
    ];

    extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk
    ];
  };

  # ===========================================================================
  # CPU MICROCODE
  # ===========================================================================

  # See if hardware-configuration.nix add it
  # hardware.cpu.amd.updateMicrocode = true;

  # ===========================================================================
  # WAYLAND (Sway) WORKAROUNDS
  # ===========================================================================

  # NVIDIA specific env variables
  programs.sway.extraSessionCommands = ''
    export WLR_NO_HARDWARE_CURSORS=1
    export __GLX_VENDOR_LIBRARY_NAME=mesa
  '';
}
