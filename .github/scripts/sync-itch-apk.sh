#!/usr/bin/env bash
set -e
load_config(){
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
if [ "$ACTION" = "deleted" ]; then
 echo "👀 removed — deleting itch.io channels"
 CHANNELS=$(butler status "$PROJECT" \
  | grep channel \
  | awk '{print $2}')
 for channel in $CHANNELS; do
  echo "Removing channel $channel"
  butler rm "$PROJECT:$channel" || true
 done
 exit 0
fi
install_butler(){
 CACHE_DIR="$HOME/.butler/bin"
 BUTLER_BIN="$CACHE_DIR/butler"
 VERSION_FILE="$CACHE_DIR/version.txt"
 mkdir -p "$CACHE_DIR"
 echo "Checking latest Butler version..."
 LATEST_VERSION=$(curl -s \
  https://api.github.com/repos/itchio/butler/releases/latest \
  | grep '"tag_name":' \
  | head -1 \
  | cut -d '"' -f4)
 if [ -f "$VERSION_FILE" ]; then
  INSTALLED_VERSION=$(cat "$VERSION_FILE")
 else
  INSTALLED_VERSION=""
 fi
 if [ -f "$BUTLER_BIN" ] && [ "$INSTALLED_VERSION" = "$LATEST_VERSION" ]; then
  echo "Butler up-to-date ($LATEST_VERSION) — using cache"
  export PATH="$CACHE_DIR:$PATH"
  return
 fi
 echo "Updating Butler: $INSTALLED_VERSION → $LATEST_VERSION"
 BUTLER_URL=$(cat .github/config/butler-url.txt | tr -d '\n')
 curl -L "$BUTLER_URL" -o butler.zip
 unzip butler.zip
 chmod +x butler
 mv butler "$BUTLER_BIN"
 echo "$LATEST_VERSION" > "$VERSION_FILE"
 export PATH="$CACHE_DIR:$PATH"
}
install_butler
mkdir -p build
curl -L \
 -H "Authorization: Bearer $GH_TOKEN" \
 https://api.github.com/repos/$GITHUB_REPOSITORY/releases/$RELEASE_ID/assets \
 | grep browser_download_url \
 | grep apk \
 | cut -d '"' -f 4 \
 | while read url; do
 curl -L \
  -H "Authorization: Bearer $GH_TOKEN" \
  "$url" \
  -o build/$(basename "$url")
if ! ls build/*.apk 1> /dev/null 2>&1; then
 echo "No APK files found"
 exit 0
fi
detect_channel(){
 FILE="$1"
 if echo "$FILE" | grep -i arm64; then
  ABI="android-arm64"
 elif echo "$FILE" | grep -i armv7; then
  ABI="android-armv7"
 else
  ABI="android-universal"
 fi
 if echo "$FILE" | grep -i nightly; then
  BUILD="nightly"
 elif echo "$FILE" | grep -i beta; then
  BUILD="beta"
 elif echo "$FILE" | grep -i debug; then
  BUILD="debug"
 else
  BUILD="release"
 fi
 if [ "$BUILD" = "release" ]; then
  echo "$ABI"
 else
  echo "$ABI-$BUILD"
 fi
}
for apk in build/*.apk; do
 CHANNEL=$(detect_channel "$apk")
 echo "Uploading $apk → $CHANNEL"
 butler push \
  "$apk" \
  "$PROJECT:$CHANNEL" \
  --userversion "$VERSION"
done