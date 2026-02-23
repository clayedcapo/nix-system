# Future Improvements

------------------------------------------------------------------------

## 1. Containers & Virtualization

### Podman (Docker Alternative)

Rootless containers without a daemon. Recommended for NixOS.

``` nix
# configuration.nix
virtualisation.podman = {
  enable = true;
  dockerCompat = true;                        # Alias docker → podman
  defaultNetwork.settings.dns_enabled = true; # Container DNS resolution
};

# Optional: Configure registries
virtualisation.containers.registries.search = [ "docker.io" "ghcr.io" ];
```

**Usage:**

``` bash
podman run -d --name postgres -e POSTGRES_PASSWORD=secret -p 5432:5432 postgres
podman run -d --name redis -p 6379:6379 redis
podman-compose up -d  # Docker Compose compatibility
```

### Kubernetes (K3s - Lightweight)

``` nix
# configuration.nix
services.k3s = {
  enable = true;
  role = "server";  # or "agent" for worker nodes
};
```

**Alternatives:**

- `minikube` - Local dev cluster
- `kind` - Kubernetes in Docker/Podman

### Virtual Machines (libvirt/QEMU)

``` nix
# configuration.nix
virtualisation.libvirtd = {
  enable = true;
  qemu.ovmf.enable = true;  # UEFI support
  qemu.swtpm.enable = true; # TPM emulation
};

programs.virt-manager.enable = true;  # GUI

# Add user to libvirtd group
users.users.clayedcapo.extraGroups = [ "libvirtd" ];
```

**Resources:**

- https://nixos.wiki/wiki/Podman
- https://nixos.wiki/wiki/Libvirt
- https://nixos.wiki/wiki/Kubernetes

------------------------------------------------------------------------

## 2. Development Environments

### The Problem

Installing language toolchains globally causes:

- Version conflicts between projects
- Polluted global environment
- Non-reproducible setups

### The Solution: direnv + Nix Flakes

``` nix
# home.nix
programs.direnv = {
  enable = true;
  nix-direnv.enable = true;    # Caches environments (much faster)
  enableZshIntegration = true;
  enableBashIntegration = true;
};
```

### Per-Project Setup

**1. Create project flake:**

``` nix
# my-project/flake.nix
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }: {
    devShells.x86_64-linux.default = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in pkgs.mkShell {
      packages = with pkgs; [
        rustc cargo rust-analyzer  # Rust
        # nodejs_20 pnpm           # Node
        # python311 poetry         # Python
      ];

      shellHook = ''
        echo "Dev environment loaded"
      '';
    };
  };
}
```

**2. Create .envrc:**

``` bash
# my-project/.envrc
use flake
```

**3. Allow direnv:**

``` bash
cd my-project
direnv allow
# Environment auto-loads on cd!
```

### Alternative: devbox

Simpler UX if Nix flakes feel complex:

``` bash
devbox init
devbox add python@3.11 nodejs@20
devbox shell
```

**Resources:**

- https://nixos.wiki/wiki/Development_environment_with_nix-shell
- https://devenv.sh/
- https://www.jetpack.io/devbox/

------------------------------------------------------------------------

## 3. Secure Boot & Hardening

### Lanzaboote (Secure Boot)

Enables UEFI Secure Boot with NixOS.

``` nix
# flake.nix - add input
inputs.lanzaboote = {
  url = "github:nix-community/lanzaboote/v0.4.1";
  inputs.nixpkgs.follows = "nixpkgs";
};

# configuration.nix
{ inputs, lib, ... }: {
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  # Disable systemd-boot (lanzaboote replaces it)
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };
}
```

**Setup steps:**

``` bash
# Generate secure boot keys
sudo sbctl create-keys

# Rebuild
sudo nixos-rebuild switch --flake .#main

# Verify (should show signed)
sudo sbctl verify

# Enroll keys in BIOS
sudo sbctl enroll-keys --microsoft
# Reboot and enable Secure Boot in BIOS
```

### Additional Hardening

``` nix
# configuration.nix
boot.kernelParams = [
  "lockdown=confidentiality"  # Kernel lockdown
];

security.apparmor.enable = true;
security.audit.enable = true;

# Restrict kernel module loading
boot.kernel.sysctl = {
  "kernel.modules_disabled" = 1;  # After boot
  "kernel.kptr_restrict" = 2;     # Hide kernel pointers
  "kernel.dmesg_restrict" = 1;    # Restrict dmesg
};
```

**Resources:**

- https://github.com/nix-community/lanzaboote
- https://nixos.wiki/wiki/Security

------------------------------------------------------------------------

## 4. Declarative State (Preservation/Impermanence)

### The Problem

NixOS is declarative for packages/config, but `/home`, `/var`, etc. accumulate state over time.

### The Solution

Use tmpfs for `/` and explicitly persist only what you need.

### Impermanence (More Mature)

``` nix
# flake.nix input
inputs.impermanence.url = "github:nix-community/impermanence";

# configuration.nix
{ inputs, ... }: {
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  # Root is tmpfs (wiped on reboot)
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=2G" "mode=755" ];
  };

  # Persist specific paths
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/systemd"
      "/etc/NetworkManager/system-connections"
    ];
    files = [
      "/etc/machine-id"
    ];
    users.clayedcapo = {
      directories = [
        "Documents"
        "Downloads"
        "Projects"
        ".config/nixos"
        ".ssh"
        ".gnupg"
        ".local/share/zoxide"
      ];
    };
  };
}
```

### Preservation (Newer Alternative)

Similar concept, different implementation:

- https://github.com/nix-community/preservation

### Benefits

- Clean system on every boot
- Explicit about what state you keep
- Easy to reproduce on new machine
- Catches accidental state dependencies

**Resources:**

- https://github.com/nix-community/impermanence
- https://grahamc.com/blog/erase-your-darlings/
- https://mt-caret.github.io/blog/posts/2020-06-29-opinionated-nix-flakes.html

------------------------------------------------------------------------

## 5. Gaming on NixOS

### Steam

``` nix
# configuration.nix
programs.steam = {
  enable = true;
  remotePlay.openFirewall = true;
  dedicatedServer.openFirewall = true;
};

# For Proton/Wine
programs.steam.gamescopeSession.enable = true;

# 32-bit support (required for many games)
hardware.graphics.enable32Bit = true;
```

### Gamemode (Performance Optimization)

``` nix
programs.gamemode = {
  enable = true;
  settings = {
    general = {
      renice = 10;
    };
    gpu = {
      apply_gpu_optimisations = "accept-responsibility";
      gpu_device = 0;
    };
  };
};
```

**Usage:**

``` bash
gamemoderun ./game
# Or configure Steam: gamemoderun %command%
```

### NVIDIA (Main Laptop)

Games should run on NVIDIA GPU:

``` bash
prime-run steam
# Or in Steam launch options: prime-run %command%
```

### Lutris (Non-Steam Games)

``` nix
# home.nix
home.packages = with pkgs; [
  lutris
  wine
  winetricks
];
```

### Nix-Gaming (Community Flake)

Additional gaming packages and optimizations:

``` nix
# flake.nix
inputs.nix-gaming.url = "github:fufexan/nix-gaming";

# Use packages like:
# inputs.nix-gaming.packages.${system}.osu-lazer-bin
```

**Resources:**

- https://nixos.wiki/wiki/Steam
- https://nixos.wiki/wiki/Lutris
- https://github.com/fufexan/nix-gaming

------------------------------------------------------------------------

## Quick Priority Reference

| Item                      | Effort | Impact | When                               |
| ------------------------- | ------ | ------ | ---------------------------------- |
| direnv + dev environments | Low    | High   | First - essential for development  |
| Podman                    | Low    | Medium | When you need containers           |
| Secure Boot               | Medium | Medium | When security matters              |
| Gaming                    | Low    | High   | When you want to game              |
| Impermanence              | High   | High   | Advanced - requires repartitioning |
| VMs (libvirt)             | Medium | Medium | When you need full VMs             |
| Kubernetes                | High   | Low    | Only if you need k8s locally       |

