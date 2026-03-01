#!/bin/bash
# This script requires create-dmg to be installed from https://github.com/sindresorhus/create-dmg
BUILD_CONFIG=$1

fail()
{
	echo "$1" 1>&2
	exit 1
}

if [ "$BUILD_CONFIG" != "Debug" ] && [ "$BUILD_CONFIG" != "Release" ]; then
  fail "Invalid build configuration - expected 'Debug' or 'Release'"
fi

BUILD_ROOT=$PWD/build
SOURCE_ROOT=$PWD
BUILD_FOLDER=$BUILD_ROOT/build-$BUILD_CONFIG
INSTALLER_FOLDER=$BUILD_ROOT/installer-$BUILD_CONFIG

if command -v qmake6 >/dev/null 2>&1; then
  QMAKE_BIN=qmake6
elif command -v qmake >/dev/null 2>&1; then
  QMAKE_BIN=qmake
else
  fail "Neither qmake6 nor qmake was found in PATH"
fi

if [ -n "$CI_VERSION" ]; then
  VERSION=$CI_VERSION
else
  VERSION=`cat $SOURCE_ROOT/app/version.txt`
fi

echo Cleaning output directories
rm -rf $BUILD_FOLDER
rm -rf $INSTALLER_FOLDER
mkdir -p $BUILD_ROOT
mkdir -p $BUILD_FOLDER
mkdir -p $INSTALLER_FOLDER

echo Cleaning in-tree intermediate artifacts
rm -rf "$SOURCE_ROOT/app/release" "$SOURCE_ROOT/app/debug"
rm -rf "$SOURCE_ROOT/moonlight-common-c/release" "$SOURCE_ROOT/moonlight-common-c/debug"
rm -rf "$SOURCE_ROOT/qmdnsengine/release" "$SOURCE_ROOT/qmdnsengine/debug"
rm -rf "$SOURCE_ROOT/h264bitstream/release" "$SOURCE_ROOT/h264bitstream/debug"

echo Configuring the project
pushd $BUILD_FOLDER
echo "Using qmake binary: $QMAKE_BIN"
$QMAKE_BIN $SOURCE_ROOT/moonlight-qt.pro || fail "Qmake failed!"
popd

echo Compiling Maclight in $BUILD_CONFIG configuration
pushd $BUILD_FOLDER
make -j$(sysctl -n hw.logicalcpu) $(echo "$BUILD_CONFIG" | tr '[:upper:]' '[:lower:]') || fail "Make failed!"
popd

echo Saving dSYM file
pushd $BUILD_FOLDER
dsymutil app/Maclight.app/Contents/MacOS/Maclight -o Maclight-$VERSION.dsym || fail "dSYM creation failed!"
cp -R Maclight-$VERSION.dsym $INSTALLER_FOLDER || fail "dSYM copy failed!"
popd

echo Creating app bundle
EXTRA_ARGS=
if [ "$BUILD_CONFIG" == "Debug" ]; then EXTRA_ARGS="$EXTRA_ARGS -use-debug-libs"; fi
echo Extra deployment arguments: $EXTRA_ARGS
macdeployqt $BUILD_FOLDER/app/Maclight.app $EXTRA_ARGS -qmldir=$SOURCE_ROOT/app/gui -appstore-compliant || fail "macdeployqt failed!"

echo Removing dSYM files from app bundle
find $BUILD_FOLDER/app/Maclight.app/ -name '*.dSYM' | xargs rm -rf

echo Signing app bundle
# Strip existing signatures from embedded code (required for linker-signed libs)
find "$BUILD_FOLDER/app/Maclight.app/Contents/Frameworks" -type f \( -name "*.dylib" -o -name "*.framework" \) -exec codesign --remove-signature {} \; 2>/dev/null || true
codesign --remove-signature "$BUILD_FOLDER/app/Maclight.app/Contents/MacOS/Maclight" 2>/dev/null || true
# Note: --options runtime is NOT used because it's incompatible with linker-signed
# libraries on macOS 15+ and causes "different Team IDs" errors at runtime
codesign --force --deep --sign - $BUILD_FOLDER/app/Maclight.app || fail "Signing failed!"
xattr -cr $BUILD_FOLDER/app/Maclight.app

echo Creating DMG
rm -f "$INSTALLER_FOLDER/Maclight.dmg"
create-dmg "$BUILD_FOLDER/app/Maclight.app" $INSTALLER_FOLDER --overwrite --dmg-title="Maclight"
case $? in
  0) ;;
  2) ;;
  *) fail "create-dmg failed!";;
esac

# Rename to include version
mv $INSTALLER_FOLDER/Maclight*.dmg $INSTALLER_FOLDER/Maclight-$VERSION.dmg 2>/dev/null || true

echo Build successful
echo "DMG: $INSTALLER_FOLDER/Maclight-$VERSION.dmg"
