# NixOS Learning Roadmap

Areas from [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config) that are relevant to your setup but not yet covered. Organized by priority and grouped by topic.

------------------------------------------------------------------------

## 1. Secrets Management

**What:** Encrypt and manage sensitive data (SSH keys, API tokens, passwords, Wi-Fi credentials) declaratively within your NixOS config, instead of storing them in plaintext or managing them manually.

**Reference config uses:** [agenix](https://github.com/ryantm/agenix) — encrypts secrets with age, decrypts them at build/boot time using SSH host keys. Secrets are stored in a private git repo (`nix-secrets`) as `.age` files with per-secret permission levels (`noaccess`, `high_security`, `user_readable`).

**What you're missing:**

- Your `configuration.nix` has `TODO: Consider setting passwords declaratively somehow` and `TODO: Security: Consider using keyring`
- SSH keys, GPG keys, Wi-Fi passwords, git credentials — all currently managed manually
- No encrypted secrets in your repo

**Where to start:**

- `agenix` (simpler, age-based) or `sops-nix` (more features, supports multiple formats)
- See: `nix-config/secrets/nixos.nix` for a complete implementation

------------------------------------------------------------------------

## 2. Secure Boot (Lanzaboote)

**What:** Sign your boot chain so only trusted code can run at startup. Prevents boot-level rootkits and tampering. Complements your existing LUKS disk encryption.

**Reference config uses:** [lanzaboote](https://github.com/nix-community/lanzaboote) — replaces `systemd-boot` with a signed UEFI stub that verifies the kernel and initrd before boot.

**What you're missing:**

- You have `systemd-boot` + LUKS but no Secure Boot
- Without Secure Boot, an attacker with physical access could boot a modified kernel that bypasses LUKS

**Where to start:**

- [Lanzaboote quickstart](https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md)
- Requires enrolling your own Secure Boot keys (replacing vendor keys)

------------------------------------------------------------------------

## 3. System Hardening Profile

**What:** Apply kernel-level and systemd-level security hardening to reduce attack surface.

**Reference config uses:** NixOS built-in `profiles/hardened.nix` + disabling coredumps.

**What you're missing:**

- No hardening profile imported (NixOS ships one at `<nixpkgs/nixos/modules/profiles/hardened.nix>`)
- Coredumps are enabled by default (potential info leak)
- No `security.sudo.keepTerminfo` (causes terminal issues with sudo in modern terminals)

**Where to start:**

``` nix
# In configuration.nix imports:
imports = [ <nixpkgs/nixos/modules/profiles/hardened.nix> ];
systemd.coredump.enable = false;
security.sudo.keepTerminfo = true;
```

- Test thoroughly — the hardened profile disables some features (e.g., BPF, user namespaces) that may conflict with your tools

------------------------------------------------------------------------

## 4. Application Sandboxing (NixPak / Bubblewrap)

**What:** Run untrusted GUI applications (browser, Telegram, etc.) in isolated sandboxes with restricted filesystem/network/D-Bus access.

**Reference config uses:**

- [NixPak](https://github.com/nixpak/nixpak) — Flatpak-like sandboxing for Nix packages using bubblewrap
- AppArmor — MAC (Mandatory Access Control) policies for system services
- Bubblewrap wrappers for specific apps (Firefox, Telegram)

**What you're missing:**

- Vivaldi, Telegram, Zoom all run with full user permissions
- No AppArmor profiles
- No sandboxing for any application

**Where to start:**

- AppArmor is the easiest first step: `security.apparmor.enable = true;`
- NixPak for browser sandboxing is more advanced
- See: `nix-config/hardening/` directory

------------------------------------------------------------------------

## 5. nix-ld and FHS Environments

**What:** Run non-NixOS binaries (downloaded executables, proprietary tools, AppImages) without manual patching.

**Reference config uses:**

- `programs.nix-ld` — installs a dynamic linker shim at `/lib64/ld-linux-x86-64.so.2`
- `buildFHSEnv` — creates a command (`fhs`) that drops you into a FHS-compliant shell

**What you're missing:**

- Downloaded binaries (AppImages, proprietary tools) won't run out of the box on your system
- No FHS compatibility layer

**Where to start:**

``` nix
programs.nix-ld = {
  enable = true;
  libraries = with pkgs; [ stdenv.cc.cc ];
};
```

- See: `nix-config/modules/nixos/desktop/fhs.nix`

------------------------------------------------------------------------

## 6. Btrfs Snapshots & Backups

**What:** Automated filesystem snapshots and backup strategy for data recovery.

**Reference config uses:** [btrbk](https://github.com/digint/btrbk) — scheduled Btrfs snapshots with retention policies (keep 7 daily, prune after 2 days minimum). Supports remote backup targets.

**What you're missing:**

- You use Btrfs (via disko) but have no snapshot/backup strategy
- No automated recovery mechanism beyond LUKS + manual backups

**Where to start:**

- `services.btrbk` for Btrfs snapshot scheduling
- Or `restic`/`borgbackup` for file-level backups to remote storage
- See: `nix-config/modules/nixos/base/btrbk.nix`

------------------------------------------------------------------------

## 7. Password Manager (pass)

**What:** GPG-encrypted password store integrated with your existing GPG setup, with browser extensions.

**Reference config uses:** `programs.password-store` (pass) with extensions (`pass-import`, `pass-update`) + `programs.browserpass` for browser integration.

**What you're missing:**

- You have GPG fully configured but no password manager using it
- Your TODO mentions considering a keyring

**Where to start:**

- `programs.password-store.enable = true;` in home.nix
- See: `nix-config/home/base/tui/password-store/default.nix`

------------------------------------------------------------------------

## 8. VPN / Private Network (Tailscale / WireGuard)

**What:** Encrypted private network between your two laptops (and other devices), enabling secure remote access without port forwarding.

**Reference config uses:**

- [Tailscale](https://tailscale.com) — zero-config WireGuard-based mesh VPN
- WireGuard configs managed via agenix secrets

**What you're missing:**

- No VPN between your main and secondary laptops
- SSH between machines requires being on the same network

**Where to start:**

- Tailscale is the easiest: `services.tailscale.enable = true;`
- WireGuard for self-hosted alternative
- See: `nix-config/modules/nixos/desktop/networking/tailscale.nix`

------------------------------------------------------------------------

## 9. Monitoring (Prometheus + Grafana)

**What:** System metrics collection and visualization for tracking resource usage, disk health, and service status.

**Reference config uses:** Prometheus node exporter on all hosts, VictoriaMetrics for storage, Grafana for dashboards, Alertmanager for notifications.

**What you're missing:**

- No metrics collection beyond manual `btop`/`iotop` usage
- No historical data on system performance
- No alerting for disk space, high CPU, etc.

**Where to start:**

- `services.prometheus.exporters.node.enable = true;` is a lightweight first step
- Grafana dashboard for visualization
- See: `nix-config/modules/nixos/base/monitoring.nix`

------------------------------------------------------------------------

## 10. Nix Overlays

**What:** Override or extend packages in nixpkgs — patch bugs, add features, or use custom versions.

**Reference config uses:** Overlays directory with custom package modifications (e.g., fcitx5 input method patches).

**What you're missing:**

- No overlays in your config
- Commented-out overlay example in your tips section but never used

**Where to start:**

``` nix
# In flake.nix or configuration.nix:
nixpkgs.overlays = [
  (final: prev: {
    # example: override a package
    somePackage = prev.somePackage.overrideAttrs (old: { ... });
  })
];
```

- See: `nix-config/overlays/default.nix`

------------------------------------------------------------------------

## 11. Custom NixOS Modules

**What:** Write reusable, configurable NixOS modules with `mkEnableOption`/`mkOption` — the standard way to organize complex configurations.

**Reference config uses:** Extensively — gaming module with enable flag, secrets module with per-host options, modular networking configs. Uses a `scanPaths` helper to auto-import all `.nix` files in a directory.

**What you're missing:**

- Your config is a flat structure (single `configuration.nix` + `home.nix`)
- No custom modules with options — everything is hardcoded
- As your config grows, this will become harder to maintain

**Where to start:**

- Extract sections (e.g., Podman, Sway, security) into separate modules
- Use `mkEnableOption` for features that differ between hosts
- See: `nix-config/modules/nixos/desktop/gaming.nix` for a clean example

------------------------------------------------------------------------

## 12. Distributed / Remote Building

**What:** Offload Nix builds to a more powerful machine, useful when building on your secondary laptop (4GB RAM).

**Reference config uses:** `nix.distributedBuilds = true` with build machines configured via SSH.

**What you're missing:**

- Your secondary laptop (4GB RAM) likely struggles with large builds
- No mechanism to offload builds to your main laptop

**Where to start:**

``` nix
nix.distributedBuilds = true;
nix.buildMachines = [{
  hostName = "main-laptop";
  sshUser = "your-user";
  systems = [ "x86_64-linux" ];
  maxJobs = 4;
}];
```

- See: `nix-config/modules/nixos/base/remote-building.nix`

------------------------------------------------------------------------

## 13. Cross-Compilation (binfmt)

**What:** Build packages for other architectures (ARM, RISC-V) on your x86_64 machines using QEMU emulation.

**Reference config uses:** `boot.binfmt.emulatedSystems` for aarch64-linux and riscv64-linux, with `preferStaticEmulators = true` for Podman compatibility.

**What you're missing:**

- Cannot build ARM/RISC-V packages natively
- Relevant if you work with Raspberry Pi, embedded systems, or ARM servers

**Where to start:**

``` nix
boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
```

------------------------------------------------------------------------

## 14. Wireshark (Network Analysis)

**What:** GUI network packet analyzer with proper permissions setup.

**Reference config uses:** `programs.wireshark.enable` with `dumpcap.enable` for non-root packet capture.

**What you're missing:**

- You have `tcpdump` and `nmap` but no GUI network analyzer
- No `dumpcap` setcap wrapper for non-root capture

**Where to start:**

``` nix
programs.wireshark = {
  enable = true;
  dumpcap.enable = true;
};
# Add user to wireshark group
users.users.${username}.extraGroups = [ "wireshark" ];
```

------------------------------------------------------------------------

## 15. Gaming (Steam / GameMode)

**What:** Steam with Proton, GameScope for resolution management, GameMode for performance optimization.

**Reference config uses:** `programs.steam` with gamescope, protontricks, PipeWire low-latency, `programs.gamemode`.

**What you're missing:**

- No gaming infrastructure (if relevant to you)
- Your NVIDIA setup with PRIME offload is already well-configured for it

**Where to start:**

- `programs.steam.enable = true;`
- See: `nix-config/modules/nixos/desktop/gaming.nix`

------------------------------------------------------------------------

## 16. Preservation / Ephemeral Root (Impermanence)

**What:** Run your root filesystem as tmpfs (wiped on every boot), persisting only explicitly declared paths. Forces you to declare all state in your NixOS config.

**Reference config uses:** [preservation](https://github.com/nix-community/preservation) (successor to impermanence) — defines which paths survive reboots.

**What you're missing:**

- Your root filesystem persists everything (standard setup)
- This is an advanced technique that maximizes reproducibility

**Where to start:**

- This is an advanced topic — study it after mastering secrets and modules
- See: [NixOS Wiki - Impermanence](https://wiki.nixos.org/wiki/Impermanence)

------------------------------------------------------------------------

## 17. Binary Caches (Cachix)

**What:** Use community or private binary caches to avoid building packages from source.

**Reference config uses:** `extra-substituters` in flake.nix for nix-gaming and wayland caches.

**What you're missing:**

- Building everything from source when not in the official cache
- No private cache for sharing builds between your two machines

**Where to start:**

``` nix
# In flake.nix nixConfig:
nixConfig = {
  extra-substituters = [ "https://nix-community.cachix.org" ];
  extra-trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
};
```

------------------------------------------------------------------------

## Suggested Learning Order

| Phase        | Topics                                                   | Why                          |
| ------------ | -------------------------------------------------------- | ---------------------------- |
| **Now**      | nix-ld/FHS (#5), Custom modules (#11)                    | Practical daily improvements |
| **Soon**     | Secrets (#1), Password manager (#7), Backups (#6)        | Security & data safety       |
| **Next**     | Secure Boot (#2), Hardening (#3), Sandboxing (#4)        | Defense in depth             |
| **Later**    | Tailscale (#8), Remote building (#12), Overlays (#10)    | Multi-machine workflow       |
| **Advanced** | Monitoring (#9), Impermanence (#16), Binary caches (#17) | Deep NixOS mastery           |

