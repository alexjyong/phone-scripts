#!/data/data/com.termux/files/usr/bin/bash
# Run JVM unit tests for an Android project inside proot.
# Usage: android-test.sh <project-dir> [fully.qualified.TestClass ...]
#        with no class args, runs the whole unit test suite (slow on a phone).
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/phone-env.sh"

PROJECT_DIR="$(cd "${1:?Usage: android-test.sh <project-dir> [TestClass...]}" && pwd)"
shift
if [ ! -x "$PROJECT_DIR/gradlew" ]; then
    echo "No gradlew in $PROJECT_DIR" >&2
    exit 1
fi
phone_load_conf
phone_init_env

GRADLE_ARGS=(
    -DskipFormatKtlint
    -Dorg.gradle.jvmargs="$GRADLE_JVMARGS"
    -Dorg.gradle.workers.max=2
    -Pkotlin.compiler.execution.strategy=in-process
    -Pandroid.aapt2FromMavenOverride="$AAPT2_OVERRIDE"
    --parallel --build-cache
    "$ANDROID_MODULE:$TEST_TASK"
)
for cls in "$@"; do
    GRADLE_ARGS+=(--tests "$cls")
done

phone_gradle "$PROJECT_DIR" "${GRADLE_ARGS[@]}"
