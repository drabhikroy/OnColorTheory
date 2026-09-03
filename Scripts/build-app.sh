#!/bin/zsh

set -euo pipefail

project_directory="${0:A:h:h}"
configuration="${1:-debug}"

if [[ "$configuration" != "debug" && "$configuration" != "release" ]]; then
    print -u2 "Usage: Scripts/build-app.sh [debug|release]"
    exit 2
fi

cd "$project_directory"
mkdir -p .build/ModuleCache .build/swiftpm-cache Build

export CLANG_MODULE_CACHE_PATH="$project_directory/.build/ModuleCache"
export SWIFTPM_MODULECACHE_OVERRIDE="$project_directory/.build/ModuleCache"
export XDG_CACHE_HOME="$project_directory/.build/swiftpm-cache"

swift build --disable-sandbox --configuration "$configuration" -j 1
binary_directory="$(swift build --disable-sandbox --configuration "$configuration" --show-bin-path)"
app_bundle="$project_directory/Build/On Color Theory.app"
staging_directory="$(mktemp -d '/private/tmp/oncolortheory-build.XXXXXX')"
staged_app="$staging_directory/On Color Theory.app"
trap 'rm -rf -- "$staging_directory"' EXIT

if [[ -e "$app_bundle" ]]; then
    rm -rf -- "$app_bundle"
fi

mkdir -p "$staged_app/Contents/MacOS" "$staged_app/Contents/Resources"
cp "$binary_directory/OnColorTheoryApp" "$staged_app/Contents/MacOS/OnColorTheoryApp"
cp "$project_directory/Support/Info.plist" "$staged_app/Contents/Info.plist"
cp -R "$project_directory/Sources/OnColorTheoryApp/Resources/Fonts" "$staged_app/Contents/Resources/Fonts"
cp -R "$project_directory/Sources/OnColorTheoryApp/Resources/Licenses" "$staged_app/Contents/Resources/Licenses"

xcrun actool \
    --compile "$staged_app/Contents/Resources" \
    --platform macosx \
    --minimum-deployment-target 14.0 \
    --app-icon AppIcon \
    --output-partial-info-plist "$staging_directory/AppIconInfo.plist" \
    "$project_directory/Support/AppAssets.xcassets"

resource_bundles=("$binary_directory"/*.bundle(N))
for resource_bundle in "${resource_bundles[@]}"; do
    cp -R "$resource_bundle" "$staged_app/Contents/Resources/"
done

chmod -R u+w "$staged_app"
xattr -cr "$staged_app"

# Sign fully here, in /private/tmp, before anything moves into Build/. Build/
# sits inside this project's working copy, which lives under ~/Documents; if
# iCloud Drive's "Desktop & Documents Folders" sync is on for this Mac, its
# file provider daemon can attach its own extended attributes to a file the
# moment it appears there, and codesign refuses to sign anything carrying
# that kind of metadata. Nothing here in /private/tmp is synced, so the
# signature never has to race it.
codesign --force --deep --sign - --timestamp=none "$staged_app"
codesign --verify --deep --strict "$staged_app"

ditto --norsrc --noextattr "$staged_app" "$app_bundle"

# The copy into Build/ can still pick up file-provider metadata after the
# fact, since that folder is synced. Re-verifying (not re-signing) confirms
# the delivered bundle still matches the signature it already carries; retry
# gives any late-arriving metadata time to settle before we give up.
verify_final_bundle() {
    for attempt in 1 2 3 4 5; do
        if codesign --verify --deep --strict "$app_bundle" 2>/dev/null; then
            return 0
        fi
        sleep 2
        xattr -dr com.apple.FinderInfo "$app_bundle" 2>/dev/null || true
        xattr -dr 'com.apple.fileprovider.fpfs#P' "$app_bundle" 2>/dev/null || true
    done
    return 1
}

if ! verify_final_bundle; then
    # Every retry failed silently; run it once more without swallowing
    # stderr so the actual codesign error reaches the terminal.
    codesign --verify --deep --strict "$app_bundle"
fi
print "$app_bundle"
