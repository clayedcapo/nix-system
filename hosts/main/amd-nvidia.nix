# =============================================================================
# GPU CONFIGURATION: AMD (integrated) + NVIDIA (discrete)
# =============================================================================
# PRIME offload configuration for hybrid graphics
# AMD iGPU is primary (power saving), NVIDIA dGPU on demand (performance)
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
  # NVIDIA KERNEL PARAMETERS
  # ===========================================================================
  # Enables framebuffer device emulation through DRM driver (/dev/fb* device backed by NVIDIA GPU)
  # Required for:
  #   - Native resolution TTY consoles
  #   - Boot splash (plymouth) on NVIDIA
  #   - Framebuffer tools (fbgrab, fbterm)
  #   - Proper suspend/resume of console state
  # Without this, TTYs fall back to low resolution (1024x768 or similar).
  # Requires driver 545+ and modeset=1.
  boot.kernelParams = [ "nvidia-drm.fbdev=1" ];


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

    # Kernel Mode Setting (KMS) moves display mode configuration from userspace into the kernel's DRM subsystem.
    # Required for:
    #   - Wayland compositors (Sway, GNOME, KDE)
    #   - Seamless boot/TTY/desktop transitions (no flicker)
    #   - PRIME synchronization for hybrid GPU setups
    #   - Hardware cursor support
    # Without this, NVIDIA is limited to legacy X11 userspace modesetting.
    modesetting.enable = true;

    # -------------------------------------------------------------------------
    # PRIME Offload
    # -------------------------------------------------------------------------
    prime = {
      offload = {
        enable = true;
        # Enables commands like `prime` for manual offloading
        enableOffloadCmd = true;
      };

      # NOTE: Find with: lspci | grep -E "VGA|3D"
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

  # TODO: Explore after configuring virtualization and OCI containers
  # hardware.nvidia-container-toolkit.enable

  # ===========================================================================
  # GRAPHICS (OpenGL/Vulkan)
  # ===========================================================================
  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [
      rocm-opencl-icd
    ];

    # NOTE: Probably depricated in 25.x
    # extraPackages32 = with pkgs; [
    #   driversi686Linux.amdvlk
    # ];
  };

  # ===========================================================================
  # PACKAGES
  # ===========================================================================
  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia # htop-like task monitor
    nvtopPackages.amd
  ];

  # ===========================================================================
  # CPU MICROCODE
  # ===========================================================================
  #
  # TODO: See if hardware-configuration.nix adds it
  # hardware.cpu.amd.updateMicrocode = true;
  #
  # ===========================================================================
  # WAYLAND (Sway) WORKAROUNDS
  # ===========================================================================
  #
  # NVIDIA specific env variables:
  #   - LIBVA_DRIVER_NAME=nvidia: Tells VA-API (video acceleration API) to use NVIDIA's driver
  #   - __GLX_VENDOR_LIBRARY_NAME=nvidia: Tells OpenGL to use NVIDIA's libraries
  #   - NVD_BACKEND=direct: Uses NVIDIA's direct backend for video decoding
  #   - GBM_BACKEND=nvidia-drm: Tells GBM (Generic Buffer Management) to use NVIDIA's DRM backend
  programs.sway.extraSessionCommands = ''
    export WLR_NO_HARDWARE_CURSORS=1
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export LIBVA_DRIVER_NAME=nvidia
    export NVD_BACKEND=direct
    export GBM_BACKEND=nvidia-drm
  '';
}
