#!/usr/bin/env bash
set -e
print_error(){
 echo ""
 echo "PRE-FLIGHT CHECK FAILED"
 echo ""
 echo "$1"
 echo ""
 echo "Required setup:"
 echo "  .github/config/itch-username.txt"
 echo "  .github/config/itch-gamename.txt"
 echo "  .github/config/butler-link.txt"
 echo ""
 echo "Repository secret: BUTLER_API_KEY"
 echo ""
 echo "Release must contain at least one .apk asset"
 echo ""
 exit 1
}
check_file(){
 FILE="$1"
 if [ ! -f "$FILE" ]; then
  print_error "Missing file: $FILE"
  exit 1
 fi
 VALUE=$(cat "$FILE" | tr -d '\n')
 if [ -z "$VALUE" ]; then
  print_error "Empty file: $FILE"
  exit 1
 fi
}
check_butler_url(){
 URL_FILE=".github/config/butler-url.txt"
 CACHE_FILE=".github/cache/butler-url.sha"
 if [ ! -f "$URL_FILE" ]; then
  print_error "Missing file: $URL_FILE"
  exit 1
 fi
 BUTLER_URL=$(cat "$URL_FILE" | tr -d '\n')
 if [ -z "$BUTLER_URL" ]; then
  print_error "Butler URL is empty"
  exit 1
 fi
 URL_HASH=$(echo "$BUTLER_URL" | sha256sum | awk '{print $1}')
 if [ -f "$CACHE_FILE" ]; then
  CACHED_HASH=$(cat "$CACHE_FILE")
  if [ "$CACHED_HASH" = "$URL_HASH" ]; then
   echo "Butler URL cache hit ✔ (skipping validation)"
   return
  fi
 fi
 echo "Validating Butler URL (cache miss)..."
 HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BUTLER_URL")
 if [ "$HTTP_CODE" -ne 200 ]; then
  print_error "Butler URL not reachable (HTTP $HTTP_CODE)"
 fi
 CONTENT_TYPE=$(curl -sI "$BUTLER_URL" | grep -i content-type | head -1)
 if echo "$CONTENT_TYPE" | grep -qi "text/html"; then
  print_error "Butler URL returned HTML (invalid archive)"
  exit 1
 fi
 echo "$URL_HASH" > "$CACHE_FILE"
 echo "Butler URL validated and cached ✔"
}
check_butler_api_key(){
 if [ -z "$BUTLER_API_KEY" ]; then
  print_error "Missing secret: BUTLER_API_KEY"
  exit 1
 fi
}
check_itch_api_identity(){
 RESPONSE=$(curl -s \
  -H "Authorization: Bearer $BUTLER_API_KEY" \
  https://itch.io/api/1/me)
 if ! echo "$RESPONSE" | grep -q '"user"'; then
  print_error "BUTLER_API_KEY invalid or expired"
  exit 1
 fi
}
check_release_apk_assets(){
 if [ -z "$RELEASE_ID" ]; then
  print_error "Missing RELEASE_ID environment variable"
  exit 1
 fi
 RESPONSE=$(curl -s \
  -H "Authorization: Bearer $GH_TOKEN" \
  https://api.github.com/repos/$GITHUB_REPOSITORY/releases/$RELEASE_ID)
 APK_COUNT=$(echo "$RESPONSE" \
  | grep '"name":' \
  | grep -i '\.apk"' \
  | wc -l)
 if [ "$APK_COUNT" = "0" ]; then
  echo "No APK assets attached to GitHub Release"
  exit 0
 fi
}
check_itch_project_access(){
 USERNAME=$(cat .github/config/itch-username.txt | tr -d '\n')
 GAMENAME=$(cat .github/config/itch-gamename.txt | tr -d '\n')
 RESPONSE=$(curl -s \
  -H "Authorization: Bearer $BUTLER_API_KEY" \
  https://itch.io/api/1/$USERNAME/$GAMENAME)
 if echo "$RESPONSE" | grep -q '"errors"'; then
  print_error "itch.io project not accessible:
$USERNAME/$GAMENAME"
  exit 1
 fi
 if ! echo "$RESPONSE" | grep -q '"game"'; then
  print_error "Unexpected itch.io API response"
  exit 1
 fi
}
echo "Running pre-flight validation..."
check_release_apk_assets
check_file .github/config/itch-username.txt
check_file .github/config/itch-gamename.txt
check_butler_url
check_butler_api_key
check_itch_api_identity
check_itch_project_access
echo "Pre-flight check passed ✔"