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
 echo "  Repository secret: BUTLER_API_KEY"
 echo "  Release must contain at least one .apk asset"
 echo ""
 exit 1
}
check_file(){
 FILE="$1"
 if [ ! -f "$FILE" ]; then
  print_error "Missing file: $FILE"
 fi
 VALUE=$(cat "$FILE" | tr -d '\n')
 if [ -z "$VALUE" ]; then
  print_error "Empty file: $FILE"
 fi
}
check_itch_api_identity(){
 RESPONSE=$(curl -s \
  -H "Authorization: Bearer $BUTLER_API_KEY" \
  https://itch.io/api/1/me)
 if ! echo "$RESPONSE" | grep -q '"user"'; then
  print_error "BUTLER_API_KEY invalid or expired"
 fi
}
check_release_apk_assets(){
 if [ -z "$RELEASE_ID" ]; then
  print_error "Missing RELEASE_ID environment variable"
 fi
 RESPONSE=$(curl -s \
  -H "Authorization: Bearer $GH_TOKEN" \
  https://api.github.com/repos/$GITHUB_REPOSITORY/releases/$RELEASE_ID)
 APK_COUNT=$(echo "$RESPONSE" \
  | grep '"name":' \
  | grep -i '\.apk"' \
  | wc -l)
 if [ "$APK_COUNT" = "0" ]; then
  print_error "No APK assets attached to GitHub Release"
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
 fi
 if ! echo "$RESPONSE" | grep -q '"game"'; then
  print_error "Unexpected itch.io API response"
 fi
}
echo "Running pre-flight validation..."
check_file .github/config/itch-username.txt
check_file .github/config/itch-gamename.txt
if [ -z "$BUTLER_API_KEY" ]; then
 print_error "Missing secret: BUTLER_API_KEY"
fi
check_itch_api_identity
check_release_apk_assets
check_itch_project_access
echo "Pre-flight check passed ✔"