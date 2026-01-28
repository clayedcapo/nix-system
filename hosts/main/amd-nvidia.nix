{ config, pkgs, ... }:
{
  boot.initrd.kernelModules = [ "amdgpu" ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = true;
    # GUI configuration tool
    nvidiaSettings = true;
    # Specific driver package to use
    package = config.boot.kernelPackages.nvidiaPackages.stable;

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

    powerManagement.enable = true;

    # NOTE: experimental, not sure it will work on my machine
    # Enables dynamic power shifts between cpu and gpu as optimization
    dynamicBoost.enable = true;
  };

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

  # See if hardware-configuration.nix add it
  # hardware.cpu.amd.updateMicrocode = true;

  # NVIDIA specific env variables
  programs.sway.extraSessionCommands = ''
    export WLR_NO_HARDWARE_CURSORS=1
    export __GLX_VENDOR_LIBRARY_NAME=mesa
  '';
}
