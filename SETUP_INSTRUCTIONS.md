# NixOS Sway Setup Instructions

## Important Notes

### 1. Finding GPU Bus IDs (CRITICAL for NVIDIA PRIME)

Before you can boot with the configuration, you MUST find your correct GPU bus IDs:

``` bash
# Find your GPUs
lspci | grep -E "VGA|3D"

# Example output:
# 01:00.0 VGA compatible controller: NVIDIA Corporation ...
# 06:00.0 VGA compatible controller: Advanced Micro Devices, Inc. [AMD/ATI] ...

# Convert to NixOS format:
# "XX:YY.Z" becomes "PCI:X:Y:Z" (remove leading zeros)
# 01:00.0 → PCI:1:0:0
# 06:00.0 → PCI:6:0:0
```

Update these lines in `configuration.nix`:

``` nix
amdgpuBusId = "PCI:6:0:0";  # Your AMD GPU
nvidiaBusId = "PCI:1:0:0";  # Your NVIDIA GPU
```

### 2. NVIDIA Driver Version

The config uses `open = false` (proprietary drivers). Change to `open = true` if:

- You have RTX 20 series or newer
- You want to try the open-source kernel modules

### 3. Audio Setup

The configuration uses **PipeWire** which replaces both PulseAudio and ALSA:

- ALSA compatibility: ✓ (built-in)
- PulseAudio compatibility: ✓ (via pipewire-pulse)
- JACK compatibility: ✓ (enabled)

You don't need separate PulseAudio or ALSA packages.

## Installation Steps

### Step 1: Initial NixOS Installation

1.  Boot from NixOS installer
2.  Set up encryption password when prompted
3.  Complete base installation

### Step 2: Set Up Disko (During Installation)

``` bash
# Download disko
nix-shell -p disko

# Partition and format (this will WIPE the disk!)
sudo disko --mode disko /path/to/disko-config.nix

# Mount everything
sudo disko --mode mount /path/to/disko-config.nix

# Generate hardware config
nixos-generate-config --no-filesystems --root /mnt

# Copy your configs
sudo cp configuration.nix /mnt/etc/nixos/
sudo cp disko-config.nix /mnt/etc/nixos/

# Install
nixos-install
```

### Step 3: First Boot Setup

After installation and first boot:

``` bash
# Set your password
sudo passwd yourusername

# Find GPU bus IDs
lspci | grep -E "VGA|3D"

# Edit configuration.nix with correct bus IDs
sudo vim /etc/nixos/configuration.nix

# Rebuild
sudo nixos-rebuild switch
```

### Step 4: Set Up Home Manager

Home Manager manages user-level configurations declaratively.

#### Option A: Standalone Home Manager (Recommended for beginners)

``` bash
# Add Home Manager channel
nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz home-manager
nix-channel --update

# Install Home Manager
nix-shell '<home-manager>' -A install

# Copy home.nix to your home directory
mkdir -p ~/.config/home-manager
cp home.nix ~/.config/home-manager/home.nix

# Edit and set your username
vim ~/.config/home-manager/home.nix

# Apply configuration
home-manager switch
```

#### Option B: NixOS Module (More integrated)

Add to your `configuration.nix`:

``` nix
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
    <home-manager/nixos>  # Add this line
  ];

  # ... rest of config ...

  # Add this section at the end:
  home-manager.users.yourusername = import ./home.nix;
}
```

Then rebuild: `sudo nixos-rebuild switch`

## Starting Sway

Since you chose TTY login with manual start:

``` bash
# Login at TTY
# Then start Sway:
sway
```

### Optional: Auto-start Sway on TTY1

If you want Sway to start automatically after login on TTY1, add this to your `~/.bash_profile` or `~/.zprofile`:

``` bash
if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
  exec sway
fi
```

## Using NVIDIA GPU for Specific Applications

By default, applications use the AMD iGPU. To run something on NVIDIA:

``` bash
# The config enables 'nvidia-offload' command
nvidia-offload <command>

# Examples:
nvidia-offload glxinfo | grep "OpenGL renderer"
nvidia-offload vulkaninfo
nvidia-offload steam
```

## Customizing Waybar and Other Configs

### If you have existing configs:

You have two options:

#### 1. Use Your Existing Configs (Quick Start)

Comment out the Home Manager waybar/alacritty sections and manually copy your configs:

``` bash
mkdir -p ~/.config/waybar
cp /path/to/your/waybar/config ~/.config/waybar/config
cp /path/to/your/waybar/style.css ~/.config/waybar/style.css
```

#### 2. Convert to Nix (Recommended Long-Term)

Convert your existing configs to Nix format in `home.nix`. This makes them reproducible.

For Waybar's `config` file, use the `settings` section in `home.nix`. For Waybar's `style.css`, use the `style` section.

Example: If your `waybar/config` has:

``` json
{
  "layer": "top",
  "modules-left": ["sway/workspaces"]
}
```

Convert to Nix in `home.nix`:

``` nix
programs.waybar = {
  enable = true;
  settings = {
    mainBar = {
      layer = "top";
      modules-left = [ "sway/workspaces" ];
    };
  };
};
```

## Adding More Packages

### System-wide packages

Edit `/etc/nixos/configuration.nix`:

``` nix
environment.systemPackages = with pkgs; [
  firefox
  # ... add more packages
];
```

### User packages

Edit `~/.config/home-manager/home.nix`:

``` nix
home.packages = with pkgs; [
  discord
  # ... add more packages
];
```

Then rebuild:

``` bash
# For system packages:
sudo nixos-rebuild switch

# For user packages:
home-manager switch
```

## Searching for Packages and Options

``` bash
# Search for packages
nix-env -qaP <package-name>

# Or search online:
# https://search.nixos.org/packages

# Search for NixOS options:
# https://search.nixos.org/options

# Search for Home Manager options:
# https://nix-community.github.io/home-manager/options.html
```

## Troubleshooting

### NVIDIA Issues

If you get black screen or Sway won't start:

1.  Check `journalctl -xe` for errors
2.  Try booting with `nomodeset` kernel parameter
3.  Verify bus IDs are correct
4.  Try switching `hardware.nvidia.open` between true/false

### Audio Not Working

``` bash
# Check PipeWire status
systemctl --user status pipewire pipewire-pulse wireplumber

# Restart if needed
systemctl --user restart pipewire pipewire-pulse wireplumber

# Test audio
wpctl status
pactl list sinks
```

### Waybar Not Showing

``` bash
# Check if waybar is running
ps aux | grep waybar

# Check logs
journalctl --user -u waybar

# Restart manually
killall waybar && waybar &
```

## File Locations Summary

```
/etc/nixos/
├── configuration.nix      # System configuration (you created this)
├── disko-config.nix       # Disk layout (you created this)
└── hardware-configuration.nix  # Generated by nixos-generate-config

~/.config/home-manager/
└── home.nix              # User configuration (you created this)

# If using existing configs (not recommended long-term):
~/.config/waybar/
├── config                # Your existing waybar config
└── style.css            # Your existing waybar style

~/.config/alacritty/
└── alacritty.yml        # Your existing alacritty config
```

## Next Steps

1.  Find your GPU bus IDs
2.  Update `configuration.nix` with correct bus IDs and username
3.  Update `home.nix` with your username
4.  Install NixOS with disko
5.  Set up Home Manager
6.  Start Sway and test

## Useful Commands

``` bash
# Rebuild system configuration
sudo nixos-rebuild switch

# Rebuild Home Manager configuration
home-manager switch

# List generations (bootloader menu)
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Garbage collect old generations
sudo nix-collect-garbage -d

# Update channels
sudo nix-channel --update
nix-channel --update  # for user (Home Manager)
```
