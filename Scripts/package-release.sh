#!/bin/zsh
#
# Builds the release artifacts for a GitHub release: a source archive and a
# DMG holding the signed app bundle.
#
# Run this on macOS. It calls hdiutil, codesign, and actool, none of which
# exist anywhere else, which is why the DMG cannot be produced as part of the
# review package.
#
#   Scripts/package-release.sh
#
# Artifacts land in dist/.

set -euo pipefail

project_directory="${0:A:h:h}"
cd "$project_directory"

version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Support/Info.plist)"
build="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' Support/Info.plist)"
app_name="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleName' Support/Info.plist)"
# Matches CFBundleExecutable and every archive already shared under this name,
# rather than a slug derived from the display name, which would produce
# on-color-theory instead of OnColorTheory and disagree with the download
# links already published in the release notes.
slug="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' Support/Info.plist | sed 's/App$//')"

dist="$project_directory/dist"
rm -rf -- "$dist"
mkdir -p "$dist"

print "Packaging $app_name $version (build $build)"

# 1. Gates. A release that cannot pass its own standards is not a release.
print "\n== Standards =="
bash Scripts/standards/run-all.sh

# 2. Tests.
print "\n== Tests =="
swift test --disable-sandbox

# 3. Signed app bundle.
print "\n== App bundle =="
app_bundle="$(Scripts/build-app.sh release | tail -n 1)"
print "Built $app_bundle"

# 4. DMG. A plain read-only image with the app and a link to Applications,
#    which is what someone expects to see after opening a download.
print "\n== Disk image =="
staging="$(mktemp -d '/private/tmp/oncolortheory-dmg.XXXXXX')"
trap 'rm -rf -- "$staging"' EXIT
ditto "$app_bundle" "$staging/$(basename "$app_bundle")"
ln -s /Applications "$staging/Applications"

dmg="$dist/$slug-$version.dmg"
hdiutil create \
    -volname "$app_name $version" \
    -srcfolder "$staging" \
    -fs HFS+ \
    -format UDZO \
    -imagekey zlib-level=9 \
    -ov \
    "$dmg"
codesign --force --sign - --timestamp=none "$dmg"
print "Wrote $dmg"

# 5. Source archive, from the git index so that ignored and untracked build
#    output cannot leak into a published tarball.
print "\n== Source archive =="
source_archive="$dist/$slug-$version-source.zip"
git archive --format=zip --prefix="$slug-$version/" -o "$source_archive" HEAD
print "Wrote $source_archive"

# 6. Checksums, so a downloader can verify what they got.
print "\n== Checksums =="
cd "$dist"
shasum -a 256 *.dmg *.zip > SHA256SUMS.txt
cat SHA256SUMS.txt

print "\nDone. Artifacts are in dist/"
