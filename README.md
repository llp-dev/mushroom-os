# Mushroom OS 🍄

A personal Linux image based on Fedora 44, built on the bootc-native
`fedora-bootc` base.

## Stack

| Layer        | Tech                       |
| ------------ | -------------------------- |
| Distribution | Fedora 44                  |
| Base image   | quay.io/fedora/fedora-bootc |
| Build system | bootc                      |
| Desktop      | GNOME                      |
| GPU          | NVIDIA                     |

## Base packages

- Emacs
- Gnome
- VLC
- Zsh

## Installation

### Rebase from an existing Fedora Atomic or Universal Blue image

```bash
sudo bootc switch --enforce-container-sigpolicy ghcr.io/llp-dev/mushroom-os:latest
```

### Fresh system installation:

1. Install any Fedora Atomic / bootc-capable base (e.g., Bazzite ISO, Silverblue).
2. Rebase using the command above

## References

- [bootc](https://containers.github.io/bootc/) — bootable OCI containers
- [fedora-bootc](https://docs.fedoraproject.org/en-US/bootc/) — Fedora's bootc base image
- [Fedora Atomic](https://fedoraproject.org/atomic-desktops/) — immutable Fedora variants
- [Bazzite](https://bazzite.gg/) — Universal Blue image for fresh installs
- [Emacs](https://www.gnu.org/software/emacs/)
- [VLC](https://www.videolan.org/vlc/)
- [Zsh](https://www.zsh.org/)
- [GNOME](https://www.gnome.org/)
