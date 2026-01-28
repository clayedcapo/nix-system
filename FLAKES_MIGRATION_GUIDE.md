# NixOS Flakes Migration Guide

## What Are Flakes and Why Use Them?

### Traditional NixOS (Channels)
```
System state managed by:
├── /etc/nixos/configuration.nix
├── Global channels (nix-channel --list)
└── Implicit dependencies
```

Problems:
- Channel versions not tracked in your config
- "Works on my machine" - hard to reproduce exactly
- Global state (channels) separate from config files
- Can't easily share configs with exact dependencies

### Modern NixOS (Flakes)
```
Everything tracked in:
├── flake.nix (your config + dependencies)
├── flake.lock (exact versions of everything)
└── Other .nix files (imported by flake.nix)
```

Benefits:
- Exact reproducibility (flake.lock pins everything)
- No global state (all dependencies in flake.nix)
- Easy to share (git clone, nixos-rebuild, done)
- Faster evaluation
- Modern standard (most new configs use flakes)

## Prerequisites

1. You have a working NixOS system
2. You understand basic Nix/NixOS configuration
3. Your config is backed up (git is recommended)

## Migration Steps

### Step 1: Enable Flakes on Your Current System

Edit `/etc/nixos/configuration.nix` and add:

```nix
{ config, pkgs, ... }:

{
  # ... existing config ...

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ... rest of config ...
}
```

Then rebuild:
```bash
sudo nixos-rebuild switch
```

### Step 2: Organize Your Configuration Files

Move to `/etc/nixos` and organize files:

```bash
cd /etc/nixos

# Your files should look like:
# /etc/nixos/
# ├── configuration.nix
# ├── hardware-configuration.nix
# ├── disko-config.nix
# └── home.nix (if using Home Manager)
```

### Step 3: Create flake.nix

Create `/etc/nixos/flake.nix`:

```bash
sudo vim /etc/nixos/flake.nix
```

Use the provided `flake.nix` template, replacing:
- `yourusername` with your actual username
- `nixos` with your hostname (or keep it as "nixos")

### Step 4: Update configuration.nix for Flakes

Key changes needed in `configuration.nix`:

**REMOVE these lines:**
```nix
# Remove any channel imports:
<home-manager/nixos>
"${builtins.fetchTarball ...}/module.nix"
```

**ADD flakes support (if not already there):**
```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

**UPDATE function arguments** to accept specialArgs:
```nix
# Old:
{ config, pkgs, ... }:

# New:
{ config, pkgs, lib, inputs, pkgs-unstable, username, hostname, ... }:
```

Use the provided `configuration-flake.nix` as reference.

### Step 5: Update home.nix (if using Home Manager)

Update function arguments to use specialArgs:

```nix
# Old:
{ config, pkgs, ... }:
{
  home.username = "yourusername";
  # ...
}

# New:
{ config, pkgs, lib, inputs, pkgs-unstable, username, ... }:
{
  home.username = username;  # Use variable from flake
  # ...
}
```

Use the provided `home-flake.nix` as reference.

### Step 6: Initialize Git Repository (Highly Recommended)

Flakes work best with git:

```bash
cd /etc/nixos

# Initialize git repo
sudo git init

# Add files
sudo git add flake.nix configuration.nix hardware-configuration.nix disko-config.nix home.nix

# Initial commit
sudo git commit -m "Initial flake configuration"
```

**Important:** Flakes only see files tracked by git! If you add new files, `git add` them.

### Step 7: Generate flake.lock

```bash
cd /etc/nixos
sudo nix flake update
```

This creates `flake.lock` which pins all dependencies to exact versions.

### Step 8: Test the Flake Build

Before switching, test that it builds:

```bash
sudo nixos-rebuild build --flake /etc/nixos#nixos

# Or if you're in /etc/nixos:
sudo nixos-rebuild build --flake .#nixos
```

If there are errors, fix them before proceeding.

### Step 9: Switch to Flake Configuration

```bash
sudo nixos-rebuild switch --flake /etc/nixos#nixos

# Or shorter, if in /etc/nixos:
sudo nixos-rebuild switch --flake .#nixos
```

The `.#nixos` means:
- `.` = current directory (where flake.nix is)
- `#nixos` = configuration name (from `nixosConfigurations.nixos` in flake.nix)

### Step 10: Verify Everything Works

After reboot:
```bash
# Check system generation
nixos-rebuild list-generations

# Check Home Manager (if used)
home-manager generations

# Verify flake is active
nix flake show /etc/nixos
```

### Step 11: Commit flake.lock

```bash
cd /etc/nixos
sudo git add flake.lock
sudo git commit -m "Add flake.lock with pinned dependencies"
```

## New Workflow Commands

### Building and Switching

```bash
# Old way (channels):
sudo nixos-rebuild switch

# New way (flakes):
cd /etc/nixos
sudo nixos-rebuild switch --flake .#nixos
```

### Updating Dependencies

```bash
# Old way (channels):
sudo nix-channel --update
sudo nixos-rebuild switch

# New way (flakes):
cd /etc/nixos
sudo nix flake update          # Update all inputs
sudo nix flake update nixpkgs  # Update only nixpkgs
sudo git add flake.lock        # Track the change
sudo git commit -m "Update dependencies"
sudo nixos-rebuild switch --flake .#nixos
```

### Checking What Changed

```bash
# See what will be updated
nix flake update --commit-lock-file

# Compare input versions
nix flake metadata
```

### Rollback

```bash
# Still works the same way - select previous generation in bootloader
# Or:
sudo nixos-rebuild switch --flake .#nixos --rollback
```

## Troubleshooting

### Error: "experimental feature 'nix-command' is disabled"

Solution: You didn't enable flakes in configuration.nix. Add:
```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

### Error: "file 'something.nix' was not found in the Nix search path"

Solution: With flakes, Nix only sees files tracked by git:
```bash
cd /etc/nixos
sudo git add file-that-was-not-found.nix
```

### Error: "cannot find flake 'flake:nixpkgs'"

Solution: Run `nix flake update` to generate flake.lock

### Build works but system doesn't change

Solution: Make sure you're using `--flake` flag:
```bash
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

### Home Manager not found

Solution: Make sure Home Manager is in your flake inputs and imported properly in flake.nix

## Benefits You Now Have

✅ **Exact reproducibility** - flake.lock pins everything
✅ **No channel confusion** - all dependencies explicit
✅ **Easy sharing** - git clone someone's config, it just works
✅ **Version control friendly** - all important info in tracked files
✅ **Mix stable and unstable** - easily use packages from different nixpkgs versions
✅ **Faster builds** - flakes evaluate more efficiently
✅ **Modern tooling** - access to new Nix commands and features

## Optional: Make a Convenience Alias

Add to your shell config (~/.bashrc or ~/.zshrc):

```bash
# Rebuild system
alias nrs='cd /etc/nixos && sudo nixos-rebuild switch --flake .#nixos'

# Update flake inputs
alias nfu='cd /etc/nixos && sudo nix flake update && sudo git add flake.lock'

# Rebuild home-manager (if standalone)
alias hrs='home-manager switch --flake /etc/nixos#yourusername'
```

## Common Patterns

### Using Unstable Packages Selectively

In configuration.nix:
```nix
environment.systemPackages = with pkgs; [
  firefox              # Stable
  pkgs-unstable.neovim # Unstable
];
```

### Creating Per-Machine Configurations

In flake.nix:
```nix
nixosConfigurations = {
  desktop = nixpkgs.lib.nixosSystem {
    modules = [ ./desktop-configuration.nix ];
  };
  
  laptop = nixpkgs.lib.nixosSystem {
    modules = [ ./laptop-configuration.nix ];
  };
};
```

Then build:
```bash
sudo nixos-rebuild switch --flake .#desktop
# or
sudo nixos-rebuild switch --flake .#laptop
```

### Sharing Configurations

Push to GitHub:
```bash
cd /etc/nixos
sudo git remote add origin https://github.com/yourusername/nixos-config
sudo git push -u origin main
```

Someone else can use your config:
```bash
git clone https://github.com/yourusername/nixos-config /etc/nixos
cd /etc/nixos
# Edit hardware-configuration.nix for their hardware
sudo nixos-rebuild switch --flake .#nixos
```

## Next Steps

1. **Commit everything to git** regularly
2. **Push to GitHub/GitLab** for backup and sharing
3. **Explore others' configs** - search "nixos flakes" on GitHub
4. **Learn advanced patterns** - overlays, modules, NUR integration
5. **Consider using home-manager more** - declarative dotfiles

## Resources

- Official: https://nixos.wiki/wiki/Flakes
- Tutorial: https://nixos-and-flakes.thiscute.world/
- Examples: https://github.com/search?q=nixos+flake
- Your old config: Still works as fallback in bootloader!

## Comparison Chart

| Feature | Channels | Flakes |
|---------|----------|--------|
| Reproducibility | Approximate | Exact |
| Share configs | Hard | Easy |
| Pin versions | Manual | Automatic |
| Evaluation speed | Slower | Faster |
| Learning curve | Gentler | Steeper |
| Status | Traditional | Modern standard |
| Recommended for new users? | No | Yes |

## You're Now Using Flakes!

Your config is now:
- ✅ Fully reproducible
- ✅ Version controlled
- ✅ Easy to share
- ✅ Using modern NixOS patterns

Remember: The most important file is now `flake.lock` - it ensures you can recreate your exact system. Always commit it!
