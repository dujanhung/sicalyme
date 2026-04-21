#!/usr/bin/env bash

set -e


EVENT="$GITHUB_EVENT_NAME"
ACTION="$GITHUB_EVENT_ACTION"

VERSION="$VERSION"
STAGE="$STAGE"
ACTOR="$GITHUB_ACTOR"
TIME=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

REPO="$GITHUB_REPOSITORY"


if [ "$EVENT" = release ]; then
 RELEASE_ID="$RELEASE_ID"
else
 RELEASE_ID="$REACTION_RELEASE_ID"
fi


MARKER_START="<!-- APK_SYNC_STATUS_START -->"
MARKER_END="<!-- APK_SYNC_STATUS_END -->"


RELEASE_JSON=$(curl -s \
 -H "Authorization: Bearer $GH_TOKEN" \
 https://api.github.com/repos/$REPO/releases/$RELEASE_ID)


APK_TABLE="No APK assets attached."


CHANNEL_RESULTS="No channel updates performed."


CHANNEL_LINKS="No channels available."


DASHBOARD=$(cat <<EOF
$MARKER_START
## 📦 APK Deployment Status

**Version:** $VERSION  
**Stage:** $STAGE  
**Updated:** $TIME  

### APK Assets

$APK_TABLE

### Channel Results

$CHANNEL_RESULTS

### Channel Links

$CHANNEL_LINKS

$MARKER_END
EOF
)


curl -s \
 -X PATCH \
 -H "Authorization: Bearer $GH_TOKEN" \
 -H "Accept: application/vnd.github+json" \
 https://api.github.com/repos/$REPO/releases/$RELEASE_ID \
 -d "{\"body\": \"$DASHBOARD\"}"