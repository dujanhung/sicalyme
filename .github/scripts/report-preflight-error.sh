#!/usr/bin/env bash
set -e


ERROR_FILE=".github/cache/preflight/error.json"


if [ ! -f "$ERROR_FILE" ]; then
 exit 0
fi


ERROR=$(cat "$ERROR_FILE")


MESSAGE=$(echo "$ERROR" | jq -r '.message')


BODY=$(curl -s \
 -H "Authorization: Bearer $GH_TOKEN" \
 https://api.github.com/repos/$GITHUB_REPOSITORY/releases/$RELEASE_ID \
 | jq -r '.body')


NEW_BODY="$BODY

---

## ❌ Preflight Failed

$message


> This deployment was blocked by preflight validation."


curl -X PATCH \
 -H "Authorization: Bearer $GH_TOKEN" \
 https://api.github.com/repos/$GITHUB_REPOSITORY/releases/$RELEASE_ID \
 -d "{\"body\":$(echo "$NEW_BODY" | jq -R -s .)}"