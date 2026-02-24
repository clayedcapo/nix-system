# =============================================================================
# GPU CONFIGURATION: AMD (integrated) + NVIDIA (discrete)
# =============================================================================
# PRIME sync configuration for hybrid graphics
# NVIDIA dGPU renders everything, AMD iGPU displays output (better compatibility)
{ config, pkgs, lib, ... }:
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
    # PRIME Sync (NVIDIA as Primary Renderer)
    # -------------------------------------------------------------------------
    # NVIDIA renders everything, AMD iGPU outputs to display
    # This ensures all apps use NVIDIA by default without per-app configuration
    prime = {
      # PRIME Sync: NVIDIA renders, AMD outputs to screen
      sync.enable = true;

      # NOTE: Find with: lspci | grep -E "VGA|3D"
      amdgpuBusId = "PCI:5:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    # -------------------------------------------------------------------------
    # Power Management
    # -------------------------------------------------------------------------
    # Enable power management through systemd
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

    # NOTE: Probably deprecated in 25.x
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
  # WAYLAND (Sway) ENVIRONMENT
  # ===========================================================================
  #
  # With PRIME sync, NVIDIA is the primary rendering GPU for all applications.
  # These environment variables ensure proper Wayland/NVIDIA integration.
  # lib.mkAfter ensures these are APPENDED to base Wayland vars in configuration.nix
  programs.sway.extraSessionCommands = lib.mkAfter ''
    # NVIDIA-specific Wayland variables
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export GBM_BACKEND=nvidia-drm
    export __VK_LAYER_NV_optimus=NVIDIA_only

    # Video acceleration
    export NVD_BACKEND=direct
    export LIBVA_DRIVER_NAME=nvidia
  '';
}
