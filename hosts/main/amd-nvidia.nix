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
  # WAYLAND (Sway) WORKAROUNDS
  # ===========================================================================
  #
  # In this PRIME offload setup, AMD iGPU is the primary GPU and handles all
  # rendering by default. NVIDIA dGPU is only used when explicitly requested
  # via `prime-run <app>` (provided by hardware.nvidia.prime.offload.enableOffloadCmd).
  #
  # The following env vars are intentionally NOT set globally:
  #   - __GLX_VENDOR_LIBRARY_NAME=nvidia — would force all OpenGL through NVIDIA,
  #     defeating offload mode and breaking apps that expect Mesa (Firefox, Electron)
  #   - LIBVA_DRIVER_NAME=nvidia — would force all VA-API (video decode) through
  #     NVIDIA, breaking hardware video acceleration on the AMD iGPU
  #   - GBM_BACKEND=nvidia-drm — would force buffer management through NVIDIA,
  #     conflicting with Mesa's native GBM on the AMD primary GPU
  #
  # NVD_BACKEND=direct is safe to set globally — it only affects NVIDIA's own
  # VA-API driver when it is actually in use (i.e., via prime-run).
  programs.sway.extraSessionCommands = ''
    export NVD_BACKEND=direct
  '';
}
