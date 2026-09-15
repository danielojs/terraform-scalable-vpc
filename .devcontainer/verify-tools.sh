#!/usr/bin/env bash
set -euo pipefail

for tool in aws terraform session-manager-plugin git jq curl dig shellcheck; do
  command -v "$tool" >/dev/null || { echo "Missing tool: $tool" >&2; exit 1; }
done
aws --version
terraform version
session-manager-plugin --version
test "$(terraform version -json | jq -r .terraform_version)" = "1.16.2"
[[ "$(aws --version)" == aws-cli/2.36.45\ * ]]
test "$(session-manager-plugin --version)" = "1.2.835.0"
echo "Tool checks passed. AWS login is a separate step; see docs/codespaces.md."
