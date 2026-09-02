#!/data/data/com.termux/files/usr/bin/bash
# Shared environment for the android-* scripts. Source me; never run me.
# Call phone_load_conf (after PROJECT_DIR is set) then phone_init_env.

TERMUX_HOME="/data/data/com.termux/files/home"

# Load per-project overrides from <project>/phone-build.conf (if present),
# falling back to standard single-module Android project defaults.
phone_load_conf() {
    ANDROID_MODULE=":app"
    ASSEMBLE_TASK="assembleDebug"
    TEST_TASK="testDebugUnitTest"
    APK_PATH="app/build/outputs/apk/debug/app-debug.apk"
    ANDROID_PLATFORM="android-36.1"
    JDK_VERSION="21"
    if [ -n "$PROJECT_DIR" ] && [ -f "$PROJECT_DIR/phone-build.conf" ]; then
        # shellcheck disable=SC1091
        . "$PROJECT_DIR/phone-build.conf"
    fi
}

# Resolve the machine-level paths. Call after phone_load_conf.
phone_init_env() {
    PHONE_CONTAINER="${PHONE_CONTAINER:-ubuntu}"
    ANDROID_SDK="${ANDROID_SDK:-$TERMUX_HOME/android-sdk}"
    JAVA_HOME="/usr/lib/jvm/java-$JDK_VERSION-openjdk-arm64"
    GRADLE_USER_HOME="$TERMUX_HOME/.gradle"
    AAPT2_OVERRIDE="$ANDROID_SDK/aapt2-android/build-tools/aapt2"
    # JVM/worker flags tuned for ~7GB-RAM phones — do not "clean up"
    GRADLE_JVMARGS="-Xmx2560m -XX:MaxMetaspaceSize=1g --add-opens jdk.compiler/com.sun.tools.javac.model=ALL-UNNAMED"
}

# Run a gradle invocation inside the proot container with the standard env.
# usage: phone_gradle <project-dir> <gradle args...>
phone_gradle() {
    local dir="$1"
    shift
    proot-distro login "$PHONE_CONTAINER" -- /bin/bash -c '
        set -e
        export ANDROID_HOME='"$ANDROID_SDK"'
        export ANDROID_SDK_ROOT=$ANDROID_HOME
        export JAVA_HOME='"$JAVA_HOME"'
        export PATH=$JAVA_HOME/bin:$PATH
        export GRADLE_USER_HOME='"$GRADLE_USER_HOME"'
        cd '"$dir"' || exit 1
        ./gradlew "$@"
    ' phone-gradle "$@"
}
