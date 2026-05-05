SHELL := /bin/bash

IMAGE_NAME ?= mushroom-os
DEFAULT_TAG ?= latest

.DEFAULT_GOAL := help

.PHONY: help
help:  ## Show this help
	@awk 'BEGIN {FS = ":.*## "; printf "Usage: make <target>\n\nTargets:\n"} \
	      /^[a-zA-Z_-]+:.*## / { printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2 }' \
	      $(MAKEFILE_LIST)

.PHONY: build
build:  ## Build the container image (override IMAGE_NAME, DEFAULT_TAG)
	@build_args=(); \
	if [ -z "$$(git status -s)" ]; then \
	  build_args+=(--build-arg "SHA_HEAD_SHORT=$$(git rev-parse --short HEAD)"); \
	fi; \
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
