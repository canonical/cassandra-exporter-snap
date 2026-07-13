set allow-duplicate-recipes
set allow-duplicate-variables
import? 'snaps.just'

[private]
@default:
  just --list
  echo ""
  echo "For help with a specific recipe, run: just --usage <recipe>"

# Update the snap to the latest upstream version
[arg("source_repo", help="Repository of the upstream project in 'org/repo' form")]
[group("maintenance")]
update source_repo:
  #!/usr/bin/env bash
  set -e

  # Fetch the latest upstream release
  latest_release="$(gh release list --repo {{source_repo}} --exclude-pre-releases --limit=1 --json tagName --jq '.[0].tagName')"
  echo "Latest release for {{source_repo}} is $latest_release"

  # Parse full semver (X.Y.Z)
  full_version="${latest_release#v}" # Strip v- prefix if present
  if [[ -z "$full_version" ]]; then
    echo "× Error: could not parse version from '$latest_release'"
    exit 1
  fi

  # Get current version from latest/ folder
  if [[ ! -f "latest/snap/snapcraft.yaml" ]]; then
    echo "× Error: latest/snap/snapcraft.yaml not found"
    exit 1
  fi
  current_version="$(yq -r '.version' latest/snap/snapcraft.yaml)"

  if [[ "$full_version" == "$current_version" ]]; then
    echo "→ Already at version $full_version, nothing to do"
    exit 0
  fi

  # Update the latest/ folder
  echo "Updating latest/ folder to version $full_version ..."
  snapcraft_file="latest/snap/snapcraft.yaml"

  full_version="$full_version" yq -i '.version = strenv(full_version)' "$snapcraft_file"
  # Update the hardcoded version variable inside override-pull
  full_version="$full_version" yq -i '
    .parts["cassandra-exporter"]["override-pull"] |=
      sub("version=\"[0-9]+\.[0-9]+\.[0-9]+\""; "version=\"" + env(full_version) + "\"")
  ' "$snapcraft_file"
  echo "✓ Updated latest/ to $full_version"
  echo "new_version=$full_version"
