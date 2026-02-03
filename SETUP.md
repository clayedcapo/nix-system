# NixOS Installation Guide

Quick reference for installing this configuration from NixOS live ISO.

## Prerequisites

- NixOS live ISO (download from nixos.org)
- USB drive for ISO
- Backup of existing data
- Network connection

------------------------------------------------------------------------

## Step 1: Boot & Connect

``` bash
# Connect to WiFi (if needed)
sudo systemctl start wpa_supplicant
wpa_cli
> add_network
> set_network 0 ssid "YourSSID"
> set_network 0 psk "YourPassword"
> enable_network 0
> quit

# Or use nmtui for easier setup
sudo nmtui
```

------------------------------------------------------------------------

## Step 2: Partition with Disko

``` bash
# Enable flakes in live environment
export NIX_CONFIG="experimental-features = nix-command flakes"

# Clone configuration
nix-shell -p git
git clone https://github.com/clayedcapo/nixos-system.git /tmp/nixos
cd /tmp/nixos

# Run disko (WARNING: This WIPES the target disk!)
sudo nix --experimental-features "nix-command flakes" run \
  github:nix-community/disko -- --mode disko --flake .#main
# Use .#secondary for the secondary laptop
```

------------------------------------------------------------------------

## Step 3: Generate Hardware Config

``` bash
# Generate hardware-configuration.nix
sudo nixos-generate-config --no-filesystems --root /mnt

# Copy to correct location
sudo cp /mnt/etc/nixos/hardware-configuration.nix /tmp/nixos/hosts/main/
# Or hosts/secondary/ for secondary laptop

# Copy config to mounted system
sudo cp -r /tmp/nixos /mnt/etc/nixos
```

------------------------------------------------------------------------

## Step 4: Find GPU Bus IDs (Main laptop only)

``` bash
lspci | grep -E "VGA|3D"
# Example output:
# 01:00.0 3D controller: NVIDIA Corporation ...
# 05:00.0 VGA compatible controller: AMD ...

# Convert format: 01:00.0 → PCI:1:0:0
# Edit hosts/main/amd-nvidia.nix with correct IDs
sudo nano /mnt/etc/nixos/hosts/main/amd-nvidia.nix
```

------------------------------------------------------------------------

## Step 5: Install NixOS

``` bash
# Install the system
sudo nixos-install --flake /mnt/etc/nixos#main
# Or #secondary for secondary laptop

# Set root password when prompted
# Set user password
sudo nixos-enter --root /mnt -c "passwd clayedcapo"

# Reboot
reboot
```

------------------------------------------------------------------------

## Step 6: Post-Install - SSH Keys

``` bash
# Generate new SSH key
ssh-keygen -t ed25519 -C "your@email.com"

# Or restore from backup
cp /path/to/backup/id_ed25519* ~/.ssh/
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# Test SSH agent (should auto-start)
ssh-add -l

# Add to services:
# GitHub: https://github.com/settings/keys
# GitLab: https://gitlab.com/-/profile/keys
```

------------------------------------------------------------------------

## Step 7: Post-Install - GPG Keys (Optional)

``` bash
# Generate new GPG key
gpg --full-generate-key

# Or import existing
gpg --import /path/to/backup/private-key.asc
gpg --import /path/to/backup/public-key.asc

# Trust your key
gpg --edit-key YOUR_KEY_ID
> trust
> 5
> quit
```

------------------------------------------------------------------------

## Step 8: Verify & Authenticate

``` bash
# Test GitHub SSH
ssh -T git@github.com

# Test GitLab SSH
ssh -T git@gitlab.com

# Authenticate GitHub CLI
gh auth login

# Authenticate GitLab CLI
glab auth login
```

------------------------------------------------------------------------

## Step 9: Move Config to Final Location

``` bash
# Move config to home directory
sudo mv /etc/nixos ~/.config/nixos
sudo chown -R $USER:users ~/.config/nixos

# Future rebuilds
cd ~/.config/nixos
sudo nixos-rebuild switch --flake .#main
```

------------------------------------------------------------------------

## Quick Reference

| Command                                    | Purpose              |
| ------------------------------------------ | -------------------- |
| `sudo nixos-rebuild switch --flake .#main` | Rebuild system       |
| `nix flake update`                         | Update all inputs    |
| `nix flake check`                          | Check for errors     |
| `sudo nixos-rebuild switch --rollback`     | Rollback to previous |


------------------------------------------------------------------------

## Troubleshooting

**Black screen after boot (NVIDIA):**

- Boot with `nomodeset` kernel parameter
- Verify GPU bus IDs are correct
- Try `hardware.nvidia.open = false`

**No WiFi:**

- Check `nmcli device` for interface name
- Use `nmtui` to connect

**Sway won't start:**

- Check logs: `journalctl --user -u sway`
- Verify all required packages are installed
