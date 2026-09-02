#!/data/data/com.termux/files/usr/bin/bash
# One-time setup: proot Ubuntu + JDK + Android SDK + static aapt2, then the
# per-project bits (platform package, local.properties) from phone-build.conf.
# Usage: android-setup.sh <project-dir>
#
# Why proot: AGP's build tools (aapt2 etc.) are glibc binaries that cannot run
# directly on Android/Termux, but run fine inside proot. Termux's own aapt2
# package is too old for modern platforms (fails on recent android.jar).
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/phone-env.sh"

PROJECT_DIR="$(cd "${1:?Usage: android-setup.sh <project-dir>}" && pwd)"
if [ ! -f "$PROJECT_DIR/gradlew" ]; then
    echo "No gradlew in $PROJECT_DIR — is this an Android project?" >&2
    exit 1
fi
phone_load_conf
phone_init_env

# proot-distro + the container
if ! command -v proot-distro > /dev/null 2>&1; then
    pkg install -y proot-distro
fi
# proot-distro >= 5.x never prints "[ok]" in list output — probe by login
if ! proot-distro login "$PHONE_CONTAINER" -- /bin/true 2>/dev/null; then
    proot-distro install "$PHONE_CONTAINER"
fi

# JDK inside the container
if ! proot-distro login "$PHONE_CONTAINER" -- /bin/bash -c \
        "test -x /usr/lib/jvm/java-$JDK_VERSION-openjdk-arm64/bin/java"; then
    proot-distro login "$PHONE_CONTAINER" -- /bin/bash -c \
        "apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq openjdk-$JDK_VERSION-jdk-headless"
fi

# Android SDK: cmdline-tools + the platform the project compiles against
if [ ! -d "$ANDROID_SDK/platforms/$ANDROID_PLATFORM" ]; then
    if [ ! -d "$ANDROID_SDK/cmdline-tools/latest" ]; then
        mkdir -p "$ANDROID_SDK/cmdline-tools"
        curl -fsSL -o "$ANDROID_SDK/cmdline-tools.zip" \
            "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
        unzip -q "$ANDROID_SDK/cmdline-tools.zip" -d "$ANDROID_SDK/tmp-ct"
        mkdir -p "$ANDROID_SDK/cmdline-tools/latest"
        mv "$ANDROID_SDK/tmp-ct/cmdline-tools/"* "$ANDROID_SDK/cmdline-tools/latest/"
        rm -rf "$ANDROID_SDK/tmp-ct" "$ANDROID_SDK/cmdline-tools.zip"
    fi
    proot-distro login "$PHONE_CONTAINER" -- /bin/bash -c \
        "export JAVA_HOME=$JAVA_HOME PATH=$JAVA_HOME/bin:\$PATH; \
         yes | $ANDROID_SDK/cmdline-tools/latest/bin/sdkmanager --licenses > /dev/null 2>&1 || true; \
         $ANDROID_SDK/cmdline-tools/latest/bin/sdkmanager --install 'platforms;$ANDROID_PLATFORM'"
fi

# Static aapt2 for aarch64: Google's Maven aapt2 "linux" artifact is x86-64
# only, so AGP needs this override to run resource compilation on ARM64.
# (Static ELF: rejected by Termux's exec wrapper, but runs fine under proot.)
if [ ! -x "$AAPT2_OVERRIDE" ]; then
    mkdir -p "$ANDROID_SDK/aapt2-android"
    curl -fsSL -o "$ANDROID_SDK/aapt2-android/ast.zip" \
        "https://github.com/lzhiyong/android-sdk-tools/releases/download/35.0.2/android-sdk-tools-static-aarch64.zip"
    unzip -q -o "$ANDROID_SDK/aapt2-android/ast.zip" -d "$ANDROID_SDK/aapt2-android"
    rm -f "$ANDROID_SDK/aapt2-android/ast.zip"
    chmod +x "$ANDROID_SDK/aapt2-android/build-tools/"*
fi

# Point Gradle at the SDK (local.properties is gitignored per project)
echo "sdk.dir=$ANDROID_SDK" > "$PROJECT_DIR/local.properties"

echo ""
echo "Setup complete for $(basename "$PROJECT_DIR")."
echo "Build: android-build.sh $PROJECT_DIR"
echo "Tests: android-test.sh $PROJECT_DIR [fully.qualified.TestClass ...]"
