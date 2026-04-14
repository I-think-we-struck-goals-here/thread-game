#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_PATH="$PROJECT_ROOT/ThreadApp.xcodeproj"
SCHEME="ThreadApp"

: "${THREAD_DEVELOPMENT_TEAM:?Set THREAD_DEVELOPMENT_TEAM to your Apple team ID before archiving.}"

ARCHIVE_PATH="${THREAD_ARCHIVE_PATH:-$PROJECT_ROOT/build/Thread.xcarchive}"
CONFIGURATION="${THREAD_CONFIGURATION:-Release}"
BUNDLE_ID="${THREAD_BUNDLE_IDENTIFIER:-co.dailythread.threadapp}"
DISPLAY_NAME="${THREAD_DISPLAY_NAME:-Daily Thread}"
SUPPORT_URL="${THREAD_SUPPORT_URL:-https://daily-thread.co/support}"
SUPPORT_EMAIL="${THREAD_SUPPORT_EMAIL:-zmailinglist@gmail.com}"
PRIVACY_URL="${THREAD_PRIVACY_POLICY_URL:-https://daily-thread.co/privacy}"
ANALYTICS_BASE_URL="${THREAD_ANALYTICS_BASE_URL:-}"
ANALYTICS_API_KEY="${THREAD_ANALYTICS_API_KEY:-}"
AGGREGATE_BASE_URL="${THREAD_AGGREGATE_BASE_URL:-}"
AGGREGATE_API_KEY="${THREAD_AGGREGATE_API_KEY:-}"

mkdir -p "$(dirname "$ARCHIVE_PATH")"

echo "Archiving Thread iOS app..."
echo "Project: $PROJECT_PATH"
echo "Archive: $ARCHIVE_PATH"
echo "Bundle ID: $BUNDLE_ID"

xcodebuild archive \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  -destination "generic/platform=iOS" \
  DEVELOPMENT_TEAM="$THREAD_DEVELOPMENT_TEAM" \
  CODE_SIGN_STYLE=Automatic \
  THREAD_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
  THREAD_DISPLAY_NAME="$DISPLAY_NAME" \
  THREAD_SUPPORT_URL="$SUPPORT_URL" \
  THREAD_SUPPORT_EMAIL="$SUPPORT_EMAIL" \
  THREAD_PRIVACY_POLICY_URL="$PRIVACY_URL" \
  THREAD_ANALYTICS_BASE_URL="$ANALYTICS_BASE_URL" \
  THREAD_ANALYTICS_API_KEY="$ANALYTICS_API_KEY" \
  THREAD_AGGREGATE_BASE_URL="$AGGREGATE_BASE_URL" \
  THREAD_AGGREGATE_API_KEY="$AGGREGATE_API_KEY"

if [[ -n "${THREAD_EXPORT_OPTIONS_PLIST:-}" ]]; then
  EXPORT_PATH="${THREAD_EXPORT_PATH:-$PROJECT_ROOT/build/export}"

  echo "Exporting archive to $EXPORT_PATH"

  xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$THREAD_EXPORT_OPTIONS_PLIST"
fi
