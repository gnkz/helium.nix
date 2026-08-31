#!/usr/bin/env bash
set -euo pipefail

api_url="https://api.github.com/repos/imputnet/helium-linux/releases/latest"

if (( $# != 0 )); then
  echo "usage: $0" >&2
  exit 2
fi

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
for required_file in flake.nix package.nix versions.nix; do
  [[ -f "$root/$required_file" ]] || {
    echo "error: $root is not a helium.nix repository" >&2
    exit 1
  }
done

data_file="$root/versions.nix"

for command in curl jq nix nix-prefetch-url; do
  command -v "$command" >/dev/null || {
    echo "error: required command not found: $command" >&2
    exit 1
  }
done

curl_args=(
  --fail
  --silent
  --show-error
  --location
  --header "Accept: application/vnd.github+json"
  --header "X-GitHub-Api-Version: 2022-11-28"
)

release_json=$(curl "${curl_args[@]}" -- "$api_url")

jq -e '
  (.draft == false)
  and (.prerelease == false)
  and (.tag_name | type == "string" and length > 0)
  and (.assets | type == "array")
' >/dev/null <<<"$release_json" || {
  echo "error: latest release is a draft, prerelease, or malformed" >&2
  exit 1
}

tag=$(jq -r '.tag_name' <<<"$release_json")
version=$tag
[[ "$version" =~ ^[0-9]+(\.[0-9]+)+$ ]] || {
  echo "error: unsupported release tag: $tag" >&2
  exit 1
}

asset_name="helium-${version}-x86_64_linux.tar.xz"
asset_count=$(jq --arg name "$asset_name" '[.assets[] | select(.name == $name)] | length' <<<"$release_json")
if [[ "$asset_count" != 1 ]]; then
  echo "error: expected exactly one asset named $asset_name, found $asset_count" >&2
  echo "available assets:" >&2
  jq -r '.assets[].name | "  " + .' <<<"$release_json" >&2
  exit 1
fi

asset=$(jq -c --arg name "$asset_name" '.assets[] | select(.name == $name)' <<<"$release_json")
state=$(jq -r '.state' <<<"$asset")
[[ "$state" == uploaded ]] || {
  echo "error: $asset_name is not in the uploaded state" >&2
  exit 1
}

asset_url=$(jq -er '.browser_download_url | select(type == "string" and length > 0)' <<<"$asset")
digest=$(jq -r '.digest // empty' <<<"$asset")
github_hash=""
if [[ -n "$digest" ]]; then
  [[ "$digest" =~ ^sha256:([0-9a-fA-F]{64})$ ]] || {
    echo "error: malformed GitHub digest for $asset_name: $digest" >&2
    exit 1
  }
  github_hash=$(nix hash convert --hash-algo sha256 --to sri "${BASH_REMATCH[1]}")
fi

current_version=$(nix eval --raw --file "$data_file" version 2>/dev/null || true)
current_hash=$(nix eval --raw --file "$data_file" hash 2>/dev/null || true)
if [[ -n "$github_hash" && "$current_version" == "$version" && "$current_hash" == "$github_hash" ]]; then
  echo "Helium is already up to date at $version"
  exit 0
fi

prefetched_hash=$(nix-prefetch-url --type sha256 "$asset_url")
hash=$(nix hash convert --hash-algo sha256 --to sri "$prefetched_hash")

if [[ -n "$github_hash" && "$hash" != "$github_hash" ]]; then
  echo "error: downloaded hash does not match GitHub's digest" >&2
  echo "  downloaded: $hash" >&2
  echo "  GitHub:     $github_hash" >&2
  exit 1
fi
if [[ -z "$github_hash" ]]; then
  echo "warning: GitHub did not provide a digest; using the downloaded hash" >&2
fi

if [[ "$current_version" == "$version" && "$current_hash" == "$hash" ]]; then
  echo "Helium is already up to date at $version"
  exit 0
fi

temporary=$(mktemp "$root/.versions.nix.XXXXXX")
trap 'rm -f "$temporary"' EXIT
printf '{\n  version = "%s";\n  hash = "%s";\n}\n' "$version" "$hash" >"$temporary"
chmod 0644 "$temporary"
mv -f "$temporary" "$data_file"
trap - EXIT

echo "Updated Helium from ${current_version:-unknown} to $version"
