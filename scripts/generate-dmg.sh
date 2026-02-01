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

echo Configuring the project
pushd $BUILD_FOLDER
qmake $SOURCE_ROOT/moonlight-qt.pro QMAKE_APPLE_DEVICE_ARCHS="x86_64 arm64" || fail "Qmake failed!"
popd

echo Compiling Moonlight in $BUILD_CONFIG configuration
pushd $BUILD_FOLDER
make -j$(sysctl -n hw.logicalcpu) $(echo "$BUILD_CONFIG" | tr '[:upper:]' '[:lower:]') || fail "Make failed!"
popd

echo Saving dSYM file
pushd $BUILD_FOLDER
dsymutil app/Moonlight.app/Contents/MacOS/Moonlight -o Moonlight-$VERSION.dsym || fail "dSYM creation failed!"
cp -R Moonlight-$VERSION.dsym $INSTALLER_FOLDER || fail "dSYM copy failed!"
popd

echo Creating app bundle
EXTRA_ARGS=
if [ "$BUILD_CONFIG" == "Debug" ]; then EXTRA_ARGS="$EXTRA_ARGS -use-debug-libs"; fi
echo Extra deployment arguments: $EXTRA_ARGS
macdeployqt $BUILD_FOLDER/app/Moonlight.app $EXTRA_ARGS -qmldir=$SOURCE_ROOT/app/gui -appstore-compliant || fail "macdeployqt failed!"

echo Removing dSYM files from app bundle
find $BUILD_FOLDER/app/Moonlight.app/ -name '*.dSYM' | xargs rm -rf

echo Signing app bundle
# Strip existing signatures from embedded code (required for linker-signed libs)
find "$BUILD_FOLDER/app/Moonlight.app/Contents/Frameworks" -type f \( -name "*.dylib" -o -name "*.framework" \) -exec codesign --remove-signature {} \; 2>/dev/null || true
codesign --remove-signature "$BUILD_FOLDER/app/Moonlight.app/Contents/MacOS/Moonlight" 2>/dev/null || true
# Note: --options runtime is NOT used because it's incompatible with linker-signed
# libraries on macOS 15+ and causes "different Team IDs" errors at runtime
codesign --force --deep --sign - $BUILD_FOLDER/app/Moonlight.app || fail "Signing failed!"
xattr -cr $BUILD_FOLDER/app/Moonlight.app

echo Creating DMG
create-dmg $BUILD_FOLDER/app/Moonlight.app $INSTALLER_FOLDER --overwrite --dmg-title="Moonlight"
case $? in
  0) ;;
  2) ;;
  *) fail "create-dmg failed!";;
esac

# Rename to include version
mv $INSTALLER_FOLDER/Moonlight*.dmg $INSTALLER_FOLDER/Moonlight-$VERSION.dmg 2>/dev/null || true

echo Build successful
echo "DMG: $INSTALLER_FOLDER/Moonlight-$VERSION.dmg"
