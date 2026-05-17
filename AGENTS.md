# Repository Guidelines

## Project Structure & Module Organization

This repository builds a personal Fedora Silverblue bootc OCI image.

- `Containerfile`: image stages, build arguments, and script entrypoints.
- `build_files/build-kmod.sh`: builds and packages NVIDIA open kernel modules for the base kernel.
- `build_files/build-base.sh`: configures repositories, package groups, NVIDIA userspace, services, and cleanup.
- `Makefile`: local build, lint, and format targets.
- `.github/workflows/`: CI image build, publishing, signing, and cleanup workflows.
- `README.md`, `cosign.pub`, `artifacthub-repo.yml`: user-facing docs and publishing metadata.

There is no application source tree or conventional test suite.

## Build, Test, and Development Commands

- `make build`: builds the image with Podman using `FEDORA_VERSION`, `NVIDIA_VERSION`, and `K6_VERSION`.
- `make build FEDORA_VERSION=44 NVIDIA_VERSION=595.58.03 K6_VERSION=1.7.1`: build with explicit version overrides.
- `make lint`: runs ShellCheck on all shell scripts.
- `make format`: runs `shfmt --write` on all shell scripts.

Use `podman build` through `make build` so build arguments stay consistent.

## Coding Style & Naming Conventions

Shell scripts use Bash with `set -Eeuo pipefail`. Prefer functions for build phases and readonly arrays for package groups, for example `CPP_PACKAGES`, `JAVA_PACKAGES`, `LUA_PACKAGES`, and `RUST_PACKAGES`.

Keep comments sparse. Add comments only for non-obvious bootc, RPM, NVIDIA, or systemd behavior. Package names should be sorted logically inside their language or purpose group, not mixed into one broad list.

Rust toolchains must stay user-level through `rustup`; do not add Fedora `rust`, `cargo`, `rustfmt`, `clippy`, or `rust-analyzer` packages to the image.

## Testing Guidelines

Run `make lint` before submitting changes. For shell-only edits, also run:

```bash
bash -n build_files/build-base.sh
bash -n build_files/build-kmod.sh
git diff --check
```

Full validation is a container build and bootc deployment test, but that is expensive and not required for every small package-list change.

## Commit & Pull Request Guidelines

Recent commits use short imperative messages, often lowercase, such as `simplify build structure` or `add VALGRIND`. Keep commits focused and describe the observable change.

Pull requests should include:

- A short summary of image/build changes.
- Any package additions or removals, with rationale.
- Whether `make lint` and syntax checks passed.
- Notes for full image builds or boot testing when not performed.
