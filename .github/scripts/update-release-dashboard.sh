#!/usr/bin/env bash
set -e

load_config () {
 FILE="$1"
 if [ ! -f "$FILE" ]; then
  echo "Missing config: $FILE"
  exit 1
 fi
 VALUE=$(cat "$FILE" | tr -d '\n')
 if [ -z "$VALUE" ]; then
  echo "Empty config: $FILE"
  exit 1
 fi
 echo "$VALUE"
}

USERNAME=$(load_config .github/config/itch-username.txt)
GAMENAME=$(load_config .github/config/itch-gamename.txt)

PROJECT="$USERNAME/$GAMENAME"


BODY=$(curl -s \
 -H "Authorization: Bearer $GH_TOKEN" \
 https://api.github.com/repos/$GITHUB_REPOSITORY/releases/$RELEASE_ID \
 | grep '"body":' \
 | sed 's/.*"body": "\(.*\)".*/\1/')


CHANNEL_LIST=$(butler status "$PROJECT" \
 | grep channel \
 | awk '{print $2}')


CHANNEL_TEXT=""

for channel in $CHANNEL_LIST; do
 CHANNEL_TEXT="$CHANNEL_TEXT
- $channel"
done

NEW_BODY="$BODY

---

### itch.io downloads

https://$USERNAME.itch.io/$GAMENAME

Available channels:$CHANNEL_TEXT"


curl -X PATCH \
 -H "Authorization: Bearer $GH_TOKEN" \
 https://api.github.com/repos/$GITHUB_REPOSITORY/releases/$RELEASE_ID \
 -d "{\"body\":\"$NEW_BODY\"}"