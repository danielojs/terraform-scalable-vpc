#!/usr/bin/env bash
set -euo pipefail

version="${1:?Pass the pinned Session Manager plugin version}"
case "$(dpkg --print-architecture)" in
  amd64) package_arch=ubuntu_64bit ;;
  arm64) package_arch=ubuntu_arm64 ;;
  *) echo "Unsupported Session Manager architecture" >&2; exit 1 ;;
esac

download_dir="$(mktemp -d)"
trap 'rm -rf "$download_dir"' EXIT
curl --fail --show-error --silent --location --retry 3 \
  --connect-timeout 20 --max-time 180 \
  "https://s3.amazonaws.com/session-manager-downloads/plugin/${version}/${package_arch}/session-manager-plugin.deb" \
  --output "$download_dir/session-manager-plugin.deb"
dpkg -i "$download_dir/session-manager-plugin.deb"
test "$(session-manager-plugin --version)" = "$version"
