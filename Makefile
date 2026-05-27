SHELL := /bin/bash

IMAGE_NAME ?= mushroom-os
DEFAULT_TAG ?= latest
FEDORA_VERSION ?= 44
NVIDIA_VERSION ?= 595.58.03

.DEFAULT_GOAL := help

.PHONY: help
help:  ## Show this help
	@awk 'BEGIN {FS = ":.*## "; printf "Usage: make <target>\n\nTargets:\n"} \
	      /^[a-zA-Z_-]+:.*## / { printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2 }' \
	      $(MAKEFILE_LIST)

.PHONY: build
build:  ## Build the container image
	@build_args=( \
	  --build-arg "FEDORA_VERSION=$(FEDORA_VERSION)" \
	  --build-arg "NVIDIA_VERSION=$(NVIDIA_VERSION)" \
	); \
	podman build "$${build_args[@]}" --pull=newer \
	  --tag "$(IMAGE_NAME):$(DEFAULT_TAG)" .

.PHONY: lint
lint:  ## Run shellcheck on all *.sh files
	@command -v shellcheck >/dev/null || { echo "shellcheck not found. Please install it."; exit 1; }
	@find . -iname "*.sh" -type f -exec shellcheck "{}" ';'

.PHONY: format
format:  ## Run shfmt --write on all *.sh files
	@command -v shfmt >/dev/null || { echo "shfmt not found. Please install it."; exit 1; }
	@find . -iname "*.sh" -type f -exec shfmt --write "{}" ';'
