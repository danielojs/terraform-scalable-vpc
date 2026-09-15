#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
check_dir="$(mktemp -d)"
trap 'rm -rf "$check_dir"' EXIT

# Validate a temporary copy: never change this working directory's backend,
# provider selection, or initialized .terraform directory.
cp "$repo_root"/*.tf "$check_dir/"
cp -R "$repo_root/modules" "$check_dir/modules"
if [[ -f "$repo_root/.terraform.lock.hcl" ]]; then
  cp "$repo_root/.terraform.lock.hcl" "$check_dir/"
  lock_flags=(-lockfile=readonly)
else
  lock_flags=()
  echo "No committed provider lock file yet; validation will resolve allowed providers."
fi
export TF_DATA_DIR="$check_dir/.terraform"
terraform -chdir="$check_dir" init -backend=false -input=false "${lock_flags[@]}"
terraform -chdir="$check_dir" validate
