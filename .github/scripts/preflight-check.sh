#!/usr/bin/env bash
set -e

STATE_DIR=".github/cache/preflight"
STATE_FILE="$STATE_DIR/state.json"
mkdir -p "$STATE_DIR"

print_error () {
 echo ""
 echo "PRE-FLIGHT CHECK FAILED"
 echo ""
 echo "$1"
 echo ""
 exit 1
}

load_state () {
 [ -f "$STATE_FILE" ] && cat "$STATE_FILE" || echo '{"config_hash":"","butler_url_hash":"","itch_me_valid":false,"itch_project_valid":false,"last_run":0}'
}

save_state () {
 echo "$1" > "$STATE_FILE"
}

STATE=$(load_state)

CONFIG_HASH=$(cat .github/config/itch-username.txt .github/config/itch-gamename.txt 2>/dev/null | sha256sum | awk '{print $1}')
BUTLER_URL=$(cat .github/config/butler-url.txt 2>/dev/null | tr -d '\n')
BUTLER_HASH=$(echo "$BUTLER_URL" | sha256sum | awk '{print $1}')

PREV_CONFIG=$(echo "$STATE" | grep -o '"config_hash":"[^"]*' | cut -d'"' -f4)
PREV_BUTLER=$(echo "$STATE" | grep -o '"butler_url_hash":"[^"]*' | cut -d'"' -f4)

FORCE_REFRESH=false
[ "$CONFIG_HASH" != "$PREV_CONFIG" ] && FORCE_REFRESH=true
[ "$BUTLER_HASH" != "$PREV_BUTLER" ] && FORCE_REFRESH=true

check_file () {
 [ ! -f "$1" ] && print_error "Missing file: $1"
}

check_file .github/config/itch-username.txt
check_file .github/config/itch-gamename.txt
check_file .github/config/butler-url.txt

check_butler_url () {
 if [ "$FORCE_REFRESH" = false ] && echo "$STATE" | grep -q '"butler_url_hash"'; then
  echo "Butler URL cache valid ✔"
  return
 fi
 HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BUTLER_URL")
 [ "$HTTP_CODE" -ne 200 ] && print_error "Butler URL not reachable (HTTP $HTTP_CODE)"
 curl -sI "$BUTLER_URL" | grep -qi "text/html" && print_error "Butler URL returned HTML"
 STATE=$(echo "$STATE" | sed "s/\"butler_url_hash\":\"[^\"]*\"/\"butler_url_hash\":\"$BUTLER_HASH\"/")
 save_state "$STATE"
 echo "Butler URL validated ✔"
}

check_itch_me () {
 if [ "$FORCE_REFRESH" = false ] && echo "$STATE" | grep -q '"itch_me_valid":true'; then
  echo "itch.io /me cache hit ✔"
  return
 fi
 RESPONSE=$(curl -s -H "Authorization: Bearer $BUTLER_API_KEY" https://itch.io/api/1/me)
 echo "$RESPONSE" | grep -q '"user"' || print_error "BUTLER_API_KEY invalid or expired"
 STATE=$(echo "$STATE" | sed 's/"itch_me_valid":false/"itch_me_valid":true/')
 save_state "$STATE"
}

check_itch_project () {
 USERNAME=$(cat .github/config/itch-username.txt | tr -d '\n')
 GAMENAME=$(cat .github/config/itch-gamename.txt | tr -d '\n')
 if [ "$FORCE_REFRESH" = false ] && echo "$STATE" | grep -q '"itch_project_valid":true'; then
  echo "itch.io project cache hit ✔"
  return
 fi
 RESPONSE=$(curl -s -H "Authorization: Bearer $BUTLER_API_KEY" https://itch.io/api/1/$USERNAME/$GAMENAME)
 echo "$RESPONSE" | grep -q '"errors"' && print_error "itch.io project not accessible"
 STATE=$(echo "$STATE" | sed 's/"itch_project_valid":false/"itch_project_valid":true/')
 save_state "$STATE"
}

echo "Running Preflight State Engine..."
check_itch_me
check_itch_project
check_butler_url

STATE=$(echo "$STATE" | sed "s/\"config_hash\":\"[^\"]*\"/\"config_hash\":\"$CONFIG_HASH\"/")
save_state "$STATE"

echo "Preflight complete ✔"