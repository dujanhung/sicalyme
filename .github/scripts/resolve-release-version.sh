set -e
if [ -z "$RELEASE_ID" ]; then
 echo "ERROR: RELEASE_ID missing"
 exit 1
fi
VERSION=$(curl -s \
 -H "Authorization: Bearer $GH_TOKEN" \
 https://api.github.com/repos/$GITHUB_REPOSITORY/releases/$RELEASE_ID \
 | grep '"tag_name":' \
 | head -1 \
 | cut -d '"' -f 4)
if [ -z "$VERSION" ]; then
 echo "ERROR: Could not resolve release version"
 exit 1
fi
echo "Resolved version: $VERSION"
echo "VERSION=$VERSION" >> "$GITHUB_ENV"