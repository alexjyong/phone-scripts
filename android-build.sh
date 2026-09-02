#!/data/data/com.termux/files/usr/bin/bash
# Build an Android project's debug APK inside proot (works for any project).
# Usage: android-build.sh <project-dir> [extra gradle args]
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/phone-env.sh"

PROJECT_DIR="$(cd "${1:?Usage: android-build.sh <project-dir> [extra gradle args]}" && pwd)"
shift
if [ ! -x "$PROJECT_DIR/gradlew" ]; then
    echo "No gradlew in $PROJECT_DIR" >&2
    exit 1
fi
phone_load_conf
phone_init_env

echo "Building $(basename "$PROJECT_DIR") ($ANDROID_MODULE:$ASSEMBLE_TASK) in proot ($PHONE_CONTAINER)..."

GRADLE_ARGS=(
    -DskipFormatKtlint
    -Dorg.gradle.jvmargs="$GRADLE_JVMARGS"
    -Dorg.gradle.workers.max=2
    -Pkotlin.compiler.execution.strategy=in-process
    -Pandroid.aapt2FromMavenOverride="$AAPT2_OVERRIDE"
    --parallel --build-cache
    "$ANDROID_MODULE:$ASSEMBLE_TASK"
)
phone_gradle "$PROJECT_DIR" "${GRADLE_ARGS[@]}" "$@"

if [ -f "$PROJECT_DIR/$APK_PATH" ]; then
    echo ""
    echo "Build successful!"
    echo "APK: $PROJECT_DIR/$APK_PATH ($(du -h "$PROJECT_DIR/$APK_PATH" | cut -f1))"
fi
