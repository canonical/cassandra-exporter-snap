# Centralized justfile for the Canonical Observability snaps
set shell := ["bash", "-uc"]

snap_name := `echo ${PWD##*/} | sed 's/-snap$//'`  # Get the snap name from the folder name

[private]
@default:
  just --list
  echo "{{snap_name}}"
  echo "For help with a specific recipe, run: just --usage <recipe>"

# Print the snap name
[group("info")]
@name:
  echo "{{snap_name}}"

# Print comma-separated list of platforms from snapcraft.yaml
[group("info")]
@platforms version="latest":
  yq -r '[.platforms | keys[]] | join(",")' "{{version}}/snap/snapcraft.yaml"

# Pack a snap locally for a specific version and architecture
[group("dev")]
pack version="latest" build_for="amd64":
  cd "{{version}}" && snapcraft pack --build-for="{{build_for}}"

# Test a snap with `snapcraft test`
[group("dev")]
test version="latest":
  #!/usr/bin/env bash
  set -e
  cp spread.yaml "{{version}}/spread.yaml"
  test_exit=0; (cd "{{version}}" && snapcraft test) || test_exit=$?
  rm -f "{{version}}/spread.yaml"
  if [ "$test_exit" -ne 0 ]; then echo "× snapcraft test failed"; exit "$test_exit"; fi
  echo "✓ 'snapcraft test' passed."

# Promote a snap to the next risk level (edge→beta→candidate→stable)
[group("release")]
[arg("from_risk", pattern="candidate|beta|edge")]
promote version="latest" from_risk="edge":
  #!/usr/bin/env bash
  set -e
  case "{{from_risk}}" in
    edge)      to_risk="beta" ;;
    beta)      to_risk="candidate" ;;
    candidate) to_risk="stable" ;;
    *) echo "× Error: invalid risk '{{from_risk}}'. Must be one of: edge, beta, candidate." && exit 1 ;;
  esac
  from_channel="{{version}}/${from_risk}"
  to_channel="{{version}}/${to_risk}"
  echo "Promoting {{snap_name}} from $from_channel → $to_channel ..."
  snapcraft promote {{snap_name}} --from-channel="$from_channel" --to-channel="$to_channel" --yes
  echo "✓ {{snap_name}} promoted to $to_channel"

# Remote-build a snap for a specific version and architecture
[group("release")]
remote-build version="latest" build_for="amd64":
  #!/usr/bin/env bash
  set -e
  cd "{{version}}"
  # snapcraft remote-build requires a git repository to be present
  git init
  echo "Starting remote build for {{snap_name}} {{version}} ({{build_for}}) ..."
  snapcraft remote-build --build-for="{{build_for}}" --launchpad-accept-public-upload
  echo "✓ Remote build complete. Snap files are in {{version}}/"

# Upload and release all snap files in the version folder to the Snap Store
[group("release")]
release version="latest":
  #!/usr/bin/env bash
  set -e
  cd "{{version}}"
  snap_files=(*.snap)
  if [[ ${#snap_files[@]} -eq 0 || ! -e "${snap_files[0]}" ]]; then
    echo "× Error: no snap files found in {{version}}/"
    exit 1
  fi
  channel="{{version}}/edge"
  for snap_file in "${snap_files[@]}"; do
    echo "Uploading and releasing $snap_file to $channel ..."
    snapcraft upload "$snap_file" --release="$channel"
    echo "✓ {{snap_name}} ($snap_file) released to $channel"
  done

# Fetch centralized files from canonical/observability
[group("maintenance")]
refresh:
  #!/usr/bin/env bash
  which -s gh || { echo "gh not found"; exit 1; }
  refresh_folder="blueprints/snaps"
  api_path="repos/canonical/observability/contents/$refresh_folder"
  for file in snaps.just spread.yaml; do
    echo "Fetching latest '$file' from canonical/observability ..."
    gh api "$api_path/$file" --jq '.content' | base64 --decode > "$file"
    echo "✓ $file updated"
  done
