set shell := ["bash", "-euo", "pipefail", "-c"]
set positional-arguments

# List available tasks.
default:
    @just --list

# Build the Helium package.
build *args:
    nix build .#helium "$@"

# Check the flake, including building and checking Helium.
check *args:
    nix flake check "$@"

# Format Nix files.
fmt *args:
    nix fmt "$@"

# Show the flake outputs.
show:
    nix flake show

# Run Helium with optional browser arguments.
run *args:
    nix run .#helium -- "$@"

# Enter the development shell.
develop:
    nix develop

# Update all flake inputs, or only the named inputs.
update-inputs *inputs:
    nix flake update "$@"

# Report whether a newer stable Helium release is available, without downloading it.
check-update:
    ./update.sh --check

# Download and verify a newer stable Helium release, then update versions.nix.
update:
    ./update.sh

# Update Helium, validate, commit versions.nix, and push to the branch's upstream.
release:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -n "$(git status --porcelain --untracked-files=all)" ]]; then
      echo "error: release requires a clean working tree and index" >&2
      exit 1
    fi
    branch=$(git symbolic-ref --quiet --short HEAD) || {
      echo "error: release requires a branch (HEAD is detached)" >&2
      exit 1
    }
    git rev-parse --verify '@{upstream}' >/dev/null 2>&1 || {
      echo "error: configure an upstream for $branch before releasing" >&2
      exit 1
    }
    remote=$(git config --get "branch.$branch.remote")
    remote_ref=$(git config --get "branch.$branch.merge")
    ./update.sh
    if git diff --quiet -- versions.nix; then
      exit 0
    fi
    nix flake check --no-update-lock-file
    version=$(nix eval --raw --file versions.nix version)
    git add -- versions.nix
    git commit -m "chore: update Helium to $version" --only -- versions.nix
    git push "$remote" "HEAD:$remote_ref"
