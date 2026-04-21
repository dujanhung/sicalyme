#!/usr/bin/env bash

set -e


# =========================
# STATE ENGINE CONFIG
# =========================

STATE_DIR=".github/cache/preflight"
STATE_FILE="$STATE_DIR/state.json"

mkdir -p "$STATE_DIR"


# =========================
# ERROR HANDLER
# =========================

print_error () {

 echo ""
 echo "PRE-FLIGHT CHECK FAILED"
 echo ""
 echo "$1"
 echo ""
 exit 1

}


# =========================
# STATE LOADER / SAVER
# =========================

load_state () {

 if [ -f "$STATE_FILE" ]; then
  cat "$STATE_FILE"
 else
  echo '{"config_hash":"","butler_url_hash":"","itch_me_valid":false,"itch_project_valid":false,"last_run":0}'
 fi

}


save_state () {

 echo "$1" > "$STATE_FILE"

}


STATE=$(load_state)


# =========================
# CONFIG HASHING
# =========================

CONFIG_HASH=$(cat .github/config/itch-username.txt .github/config/itch-gamename.txt 2>/dev/null | sha256sum | awk '{print $1}')

BUTLER_URL=$(cat .github/config/butler-url.txt 2>/dev/null | tr -d '\n')

BUTLER_HASH=$(echo "$BUTLER_URL" | sha256sum | awk '{print $1}')


PREV_CONFIG=$(echo "$STATE" | grep -o '"config_hash":"[^"]*' | cut -d'"' -f4)

PREV_BUTLER=$(echo "$STATE" | grep -o '"butler_url_hash":"[^"]*' | cut -d'"' -f4)


FORCE_REFRESH=false


if [ "$CONFIG_HASH" != "$PREV_CONFIG" ]; then
 FORCE_REFRESH=true
fi

if [ "$BUTLER_HASH" != "$PREV_BUTLER" ]; then
 FORCE_REFRESH=true
fi


# =========================
# BASIC FILE CHECKS
# =========================

check_file () {

 FILE="$1"

 if [ ! -f "$FILE" ]; then
  print_error "Missing file: $FILE"
 fi

}


check_file .github/config/itch-username.txt
check_file .github/config/itch-gamename.txt
check_file .github/config/butler-url.txt


# =========================
# BUTLER URL VALIDATION (CACHED)
# =========================

check_butler_url () {

 if [ "$FORCE_REFRESH" = false ] && echo "$STATE" | grep -q '"butler_url_hash"'; then
  echo "Butler URL cache valid ✔"
  return
 fi


 echo "Validating Butler URL..."


 HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BUTLER_URL")


 if [ "$HTTP_CODE" -ne 200 ]; then
  print_error "Butler URL not reachable (HTTP $HTTP_CODE)"
 fi


 if curl -sI "$BUTLER_URL" | grep -qi "text/html"; then
  print_error "Butler URL returned HTML (invalid archive)"
 fi


 STATE=$(echo "$STATE" | sed "s/\"butler_url_hash\":\"[^\"]*\"/\"butler_url_hash\":\"$BUTLER_HASH\"/")

 save_state "$STATE"


 echo "Butler URL validated ✔"

}


# =========================
# ITCH.IO /ME CHECK (CACHED)
# =========================

check_itch_me () {

 if [ "$FORCE_REFRESH" = false ] && echo "$STATE" | grep -q '"itch_me_valid":true'; then
  echo "itch.io /me cache hit ✔"
  return
 fi


 echo "Validating itch.io identity..."


 RESPONSE=$(curl -s \
  -H "Authorization: Bearer $BUTLER_API_KEY" \
  https://itch.io/api/1/me)


 if ! echo "$RESPONSE" | grep -q '"user"'; then
  print_error "BUTLER_API_KEY invalid or expired"
 fi


 STATE=$(echo "$STATE" | sed 's/"itch_me_valid":false/"itch_me_valid":true/')

 save_state "$STATE"

}


# =========================
# ITCH.IO PROJECT CHECK (CACHED)
# =========================

check_itch_project () {

 USERNAME=$(cat .github/config/itch-username.txt | tr -d '\n')
 GAMENAME=$(cat .github/config/itch-gamename.txt | tr -d '\n')


 if [ "$FORCE_REFRESH" = false ] && echo "$STATE" | grep -q '"itch_project_valid":true'; then
  echo "itch.io project cache hit ✔"
  return
 fi


 echo "Validating itch.io project..."


 RESPONSE=$(curl -s \
  -H "Authorization: Bearer $BUTLER_API_KEY" \
  https://itch.io/api/1/$USERNAME/$GAMENAME)


 if echo "$RESPONSE" | grep -q '"errors"'; then
  print_error "itch.io project not accessible: $USERNAME/$GAMENAME"
 fi


 STATE=$(echo "$STATE" | sed 's/"itch_project_valid":false/"itch_project_valid":true/')

 save_state "$STATE"

}


# =========================
# RUN ENGINE
# =========================

echo "Running Preflight State Engine..."


check_itch_me
check_itch_project
check_butler_url


STATE=$(echo "$STATE" | sed "s/\"config_hash\":\"[^\"]*\"/\"config_hash\":\"$CONFIG_HASH\"/")


save_state "$STATE"


echo "Preflight complete ✔"