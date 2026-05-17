# Mushroom OS 🍄

A personal [bootc](https://containers.github.io/bootc/) OCI image based on
Fedora 44 Silverblue. Published as `ghcr.io/llp-dev/mushroom-os:latest` and
signed with cosign (`cosign.pub`). Consumed via `bootc switch`.

## What it is

GNOME desktop on Fedora 44 Silverblue with NVIDIA support
(`kmod-nvidia-open` compiled from upstream against the base's exact
kernel) plus a dev-focused package set. The package lists live in
`build_files/build-base.sh`.
Rust is intentionally left to the user session for a `rustup` managed
toolchain.

## Install

From any Fedora bootc-capable host (Silverblue 44+, Kinoite, etc.):

```bash
sudo bootc switch --enforce-container-sigpolicy ghcr.io/llp-dev/mushroom-os:latest
sudo systemctl reboot
```

For a fresh system: install any [Fedora Atomic](https://fedoraproject.org/atomic-desktops/)
desktop or a [Universal Blue](https://universal-blue.org/) image
(e.g. [Bazzite](https://bazzite.gg/)), finish the installer, then run the
command above.

After first boot, opt your user into 1Password's CLI / browser integration:

```bash
sudo usermod -a -G onepassword,onepassword-cli "$USER"
```

(then log out and back in).

## Build locally

```bash
make build    # build the OCI image with podman
make lint     # shellcheck on build scripts
make format   # shfmt on build scripts
```

There is no local VM / disk-image / ISO build path; test boot on a real
bootc host or a separately-provisioned VM.

CI builds on push, PR, and a schedule; on `main` it pushes to GHCR and
signs with cosign. Tags: `latest`, `latest.YYYYMMDD`, `YYYYMMDD`.
