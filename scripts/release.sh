#!/usr/bin/env bash

# DESCRIPTION
# Automates the release process for whisper-stream.
# - Checks for a clean git state.
# - Bumps version in PKGBUILD and RPM spec file.
# - Updates .SRCINFO.
# - Commits and tags the new release.
# - Pushes to the remote repository.

set -o nounset
set -o errexit
set -o pipefail
IFS=$'\n\t'

# Ensure we are in the project root
cd "$(dirname -- "${BASH_SOURCE[0]}")"/..

# --- Pre-flight Checks ---

# Check for clean git working directory
if ! git diff-index --quiet HEAD --; then
    echo "Error: Uncommitted changes detected."
    echo "Please commit or stash your changes before releasing."
    exit 1
fi

echo "Git working directory is clean."

# Check for makepkg
if ! command -v makepkg &> /dev/null; then
    echo "Error: 'makepkg' command not found."
    echo "Please install the 'pacman-contrib' package."
    exit 1
fi

echo "Found 'makepkg'."

# --- Version Bumping ---

PKGBUILD_PATH="packaging/PKGBUILD"
SPEC_PATH="packaging/whisper-stream.spec"

# Get current version from PKGBUILD
current_pkgver=$(grep -oP 'pkgver=\K.*' "$PKGBUILD_PATH")
current_pkgrel=$(grep -oP 'pkgrel=\K.*' "$PKGBUILD_PATH")

# Get current version from spec file for verification
spec_version=$(grep -oP 'Version:\s*\K.*' "$SPEC_PATH")
spec_release=$(grep -oP 'Release:\s*\K[0-9]+' "$SPEC_PATH")

echo
echo "Current PKGBUILD version: $current_pkgver-$current_pkgrel"
echo "Current spec file version: $spec_version-$spec_release"

# Verify versions are in sync
if [[ "$current_pkgver" != "$spec_version" ]] || [[ "$current_pkgrel" != "$spec_release" ]]; then
    echo "Warning: PKGBUILD and spec file versions are not in sync!"
    echo "PKGBUILD: $current_pkgver-$current_pkgrel"
    echo "Spec file: $spec_version-$spec_release"
    read -r -p "Continue anyway? [y/N] " sync_confirmation
    if [[ ! "$sync_confirmation" =~ ^[yY](es)?$ ]]; then
        echo "Release cancelled. Please sync versions manually first."
        exit 1
    fi
fi
echo

# Ask user for the type of version bump
echo "What type of release is this?"
new_pkgver="" # Initialize to empty
new_pkgrel="" # Initialize to empty
select bump_type in "patch" "minor" "major" "release" "custom"; do
    case $bump_type in
        patch|minor|major)
            # Increment pkgver
            IFS='.' read -r -a version_parts <<< "$current_pkgver"
            case $bump_type in
                patch)
                    ((version_parts[2]++))
                    ;;
                minor)
                    ((version_parts[1]++))
                    version_parts[2]=0
                    ;;
                major)
                    ((version_parts[0]++))
                    version_parts[1]=0
                    version_parts[2]=0
                    ;;
            esac
            new_pkgver="${version_parts[0]}.${version_parts[1]}.${version_parts[2]}"
            new_pkgrel=1 # Reset pkgrel for new version
            break
            ;;
        release)
            # Increment pkgrel
            new_pkgver="$current_pkgver"
            ((new_pkgrel = current_pkgrel + 1))
            break
            ;;
        custom)
            read -r -p "Enter new pkgver: " new_pkgver
            read -r -p "Enter new pkgrel: " new_pkgrel
            if [[ -z "$new_pkgver" || -z "$new_pkgrel" ]]; then
                echo "Error: Custom version and release cannot be empty."
                exit 1
            fi
            break
            ;;
        *)
            # This case handles invalid number entry, or empty entry
            echo "Invalid option. Please try again."
            ;;
    esac
done

# Check if the select loop was exited via EOF (Ctrl+D) or invalid input
if [[ -z "$new_pkgver" || -z "$new_pkgrel" ]]; then
    echo
    echo "No selection made or invalid input. Aborting."
    exit 1
fi

echo
echo "New version: $new_pkgver"
echo "New release: $new_pkgrel"
echo

# Confirm with the user
read -r -p "Proceed with this version? [y/N] " confirmation
if [[ ! "$confirmation" =~ ^[yY](es)?$ ]]; then
    echo "Release cancelled."
    exit 0
fi

# --- Update Files ---

echo "Updating PKGBUILD..."
sed -i "s/pkgver=.*/pkgver=$new_pkgver/" "$PKGBUILD_PATH"
sed -i "s/pkgrel=.*/pkgrel=$new_pkgrel/" "$PKGBUILD_PATH"
echo "PKGBUILD updated."

echo "Updating RPM spec file..."
sed -i "s/Version:.*/Version:        $new_pkgver/" "$SPEC_PATH"
sed -i "s/Release:.*/Release:        $new_pkgrel%{?dist}/" "$SPEC_PATH"
echo "RPM spec file updated."

echo "Updating .SRCINFO..."
(
    cd packaging
    makepkg --printsrcinfo > .SRCINFO
)
echo ".SRCINFO updated."

# --- Git Operations ---

commit_message="chore(release): v$new_pkgver-$new_pkgrel"
git_tag="v$new_pkgver"

echo "Committing changes..."
git add packaging/PKGBUILD packaging/.SRCINFO packaging/whisper-stream.spec
git commit -m "$commit_message"
echo "Committed with message: $commit_message"

# Only tag new versions, not just new release numbers
if [[ "$new_pkgver" != "$current_pkgver" ]]; then
    echo "Tagging new version..."
    git tag "$git_tag"
    echo "Created git tag: $git_tag"
fi

# --- Push to Remote ---

echo
echo "The following actions will be performed:"
echo " - Push commit to remote 'origin'"
if [[ "$new_pkgver" != "$current_pkgver" ]]; then
    echo " - Push tag '$git_tag' to remote 'origin'"
fi

read -r -p "Push to remote? [y/N] " push_confirmation
if [[ ! "$push_confirmation" =~ ^[yY](es)?$ ]]; then
    echo "Push cancelled. Please push the changes manually."
    echo "  git push && git push --tags"
    exit 0
fi

echo "Pushing commit..."
git push

if [[ "$new_pkgver" != "$current_pkgver" ]]; then
    echo "Pushing tag..."
    git push origin "$git_tag"
fi

echo "Push complete."

# --- Final Instructions ---

echo
echo "Release process complete!"
echo
echo "Next steps:"
echo "1. Go to the AUR web interface for whisper-stream."
echo "2. Click 'Upload new files' under 'Package Actions'."
echo "3. Upload the 'packaging/.SRCINFO' file."
echo "4. The AUR will automatically fetch the new release from the git tag."
echo
echo "Alternatively, if you use 'aur-submit', you can just run it from the 'packaging' directory."
