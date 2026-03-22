# Mushroom OS 🍄

A personal Linux image based on Fedora 43 Atomic, built with bootc and derived
from the Universal Blue project.

## Stack

| Layer        | Tech             |
| ------------ | ---------------- |
| Distribution | Fedora 43 Atomic |
| Base image   | Universal Blue   |
| Build system | bootc            |
| Desktop      | GNOME            |
| GPU          | NVIDIA           |

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

1. Install a Universal Blue base image (e.g., Bazzite ISO).
2. Rebase using the command above

## References

- [Universal Blue](https://universal-blue.org/) — OCI-based Fedora immutable desktops
- [bootc](https://containers.github.io/bootc/) — bootable OCI containers
- [Fedora Atomic](https://fedoraproject.org/atomic-desktops/) — immutable Fedora variants
- [Bazzite](https://bazzite.gg/) — Universal Blue image for fresh installs
- [Emacs](https://www.gnu.org/software/emacs/)
- [VLC](https://www.videolan.org/vlc/)
- [Zsh](https://www.zsh.org/)
- [GNOME](https://www.gnome.org/)
