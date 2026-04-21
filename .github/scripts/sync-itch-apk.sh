#!/usr/bin/env bash

set -e


PROJECT="$USERNAME/$GAMENAME"

SUMMARY_FILE="$GITHUB_STEP_SUMMARY"
TABLE_FILE="channel_results_table.txt"
CHANNEL_FILE="channel_links.txt"

rm -f "$TABLE_FILE"
rm -f "$CHANNEL_FILE"


record_summary () {

 CHANNEL="$1"
 RESULT="$2"

 echo "| $CHANNEL | $RESULT |" >> "$SUMMARY_FILE"
 echo "$CHANNEL : $RESULT" >> "$TABLE_FILE"
 echo "$CHANNEL" >> "$CHANNEL_FILE"

}


attach_to_main_page () {

 CHANNEL="$1"

 curl -s \
  -H "Authorization: Bearer $BUTLER_API_KEY" \
  https://itch.io/api/1/$USERNAME/game/$GAMENAME/channel/$CHANNEL/attach \
  > /dev/null || true

}


fetch_release_notes () {

 RELEASE_JSON=$(curl -s \
  -H "Authorization: Bearer $GH_TOKEN" \
  https://api.github.com/repos/$GITHUB_REPOSITORY/releases/$RELEASE_ID)

 RELEASE_BODY=$(echo "$RELEASE_JSON" \
  | sed -n 's/.*"body": "\(.*\)".*/\1/p')

 CHANGELOG=$(echo "$RELEASE_BODY" \
  | sed 's/\\r//g' \
  | sed 's/\\n/\n/g')

 echo "$CHANGELOG"

}


update_channel_description () {

 CHANNEL="$1"

 NOTES=$(fetch_release_notes)

 if [ -z "$NOTES" ]; then
  NOTES="No release notes available."
 fi


 curl -s \
  -H "Authorization: Bearer $BUTLER_API_KEY" \
  -X POST \
  https://itch.io/api/1/$USERNAME/game/$GAMENAME/channel/$CHANNEL/update \
  -d "description=Version: $VERSION

$NOTES" \
  > /dev/null || true

}


MAX_PARALLEL=3
UPLOAD_PIDS=()


wait_for_slot () {

 while [ "${#UPLOAD_PIDS[@]}" -ge "$MAX_PARALLEL" ]; do

  for i in "${!UPLOAD_PIDS[@]}"; do

   if ! kill -0 "${UPLOAD_PIDS[$i]}" 2>/dev/null; then
    unset 'UPLOAD_PIDS[i]'
   fi

  done

  sleep 1

 done

}


schedule_upload () {

 FILE="$1"
 CHANNEL="$2"

 wait_for_slot

 (
  butler push "$FILE" "$PROJECT:$CHANNEL" \
   --userversion "$VERSION"

  attach_to_main_page "$CHANNEL"

  update_channel_description "$CHANNEL"

  record_summary "$CHANNEL" uploaded

 ) &

 UPLOAD_PIDS+=($!)

}


for file in build/*.apk; do

 NAME=$(basename "$file" .apk)


 if echo "$NAME" | grep arm64 > /dev/null; then
  VARIANT=arm64
 elif echo "$NAME" | grep x86 > /dev/null; then
  VARIANT=x86
 else
  VARIANT=""
 fi


 if [ "$STAGE" = nightly ]; then

  CHANNEL="android-nightly-$VARIANT"

 elif [ "$STAGE" = beta ]; then

  CHANNEL="android-beta-$VARIANT"

 else

  CHANNEL="android-$VARIANT"

 fi


 schedule_upload "$file" "$CHANNEL"

done


FAIL=0


for PID in "${UPLOAD_PIDS[@]}"; do

 if ! wait "$PID"; then
  FAIL=1
 fi

done


if [ "$FAIL" = 1 ]; then
 exit 1
fi