#!/usr/bin/env bash
set -euo pipefail

# akasha-pull.sh — poll R2 for new capture manifests, download sessions to StudyMaterials/inbox/,
# delete from R2, and trigger akasha-material-parser.

VAULT_PATH="$(cd "$(dirname "$0")/.." && pwd)"
INBOX="$VAULT_PATH/StudyMaterials/inbox"

# Verify env vars
: "${AKASHA_R2_ENDPOINT:?AKASHA_R2_ENDPOINT not set}"
: "${AKASHA_R2_BUCKET:?AKASHA_R2_BUCKET not set}"
: "${AKASHA_R2_ACCESS_KEY:?AKASHA_R2_ACCESS_KEY not set}"
: "${AKASHA_R2_SECRET_KEY:?AKASHA_R2_SECRET_KEY not set}"

# S3 signing function
function s3_signed_request() {
  local METHOD="$1"
  local OBJECT_KEY="$2"
  local PAYLOAD_FILE="$3"
  local CONTENT_TYPE="${4:-application/json}"

  local DATE_SHORT=$(date -u +"%Y%m%d")
  local DATE_LONG=$(date -u +"%Y%m%dT%H%M%SZ")
  local REGION="auto"
  local SERVICE="s3"

  local SECRET_KEY_HEX=$(echo -n "AWS4$AKASHA_R2_SECRET_KEY" | xxd -p -c 256)
  local DATE_KEY=$(echo -n "$DATE_SHORT" | openssl dgst -sha256 -hmac "$SECRET_KEY_HEX" -binary | xxd -p -c 256)
  local REGION_KEY=$(echo -n "$REGION" | openssl dgst -sha256 -hmac "$DATE_KEY" -binary | xxd -p -c 256)
  local SERVICE_KEY=$(echo -n "$SERVICE" | openssl dgst -sha256 -hmac "$REGION_KEY" -binary | xxd -p -c 256)
  local SIGNING_KEY=$(echo -n "aws4_request" | openssl dgst -sha256 -hmac "$SERVICE_KEY" -hex | awk '{print $NF}')

  local PAYLOAD_HASH
  if [ -n "$PAYLOAD_FILE" ] && [ -f "$PAYLOAD_FILE" ]; then
    PAYLOAD_HASH=$(openssl dgst -sha256 "$PAYLOAD_FILE" | awk '{print $NF}')
  else
    PAYLOAD_HASH=$(echo -n "" | openssl dgst -sha256 | awk '{print $NF}')
  fi

  local HOST="${AKASHA_R2_ENDPOINT#https://}"
  local CANONICAL_REQUEST="$METHOD\n/$OBJECT_KEY\n\nhost:$HOST\nx-amz-content-sha256:$PAYLOAD_HASH\nx-amz-date:$DATE_LONG\n\nhost;x-amz-content-sha256;x-amz-date\n$PAYLOAD_HASH"
  local CANONICAL_HASH=$(echo -ne "$CANONICAL_REQUEST" | openssl dgst -sha256 | awk '{print $NF}')
  local STRING_TO_SIGN="AWS4-HMAC-SHA256\n$DATE_LONG\n$DATE_SHORT/$REGION/s3/aws4_request\n$CANONICAL_HASH"
  local SIGNATURE=$(echo -ne "$STRING_TO_SIGN" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:$SIGNING_KEY" | awk '{print $NF}')

  curl -s -X "$METHOD" \
    -H "Host: $HOST" \
    -H "Content-Type: $CONTENT_TYPE" \
    -H "x-amz-content-sha256: $PAYLOAD_HASH" \
    -H "x-amz-date: $DATE_LONG" \
    -H "Authorization: AWS4-HMAC-SHA256 Credential=$AKASHA_R2_ACCESS_KEY/$DATE_SHORT/$REGION/s3/aws4_request,SignedHeaders=host;x-amz-content-sha256;x-amz-date,Signature=$SIGNATURE" \
    ${PAYLOAD_FILE:+-d "@$PAYLOAD_FILE"} \
    "$AKASHA_R2_ENDPOINT/$OBJECT_KEY"
}

# List manifests
echo "Scanning for capture manifests..."
MANIFEST_LISTING=$(s3_signed_request "GET" "?list-type=2&prefix=manifests/" "" "")

# Parse manifest keys (R2 returns XML)
MANIFEST_COUNT=0
echo "$MANIFEST_LISTING" | grep -oP '<Key>manifests/[^<]+</Key>' | sed 's/<Key>\(.*\)<\/Key>/\1/' | while read -r KEY; do
  SESSION_ID=$(basename "$KEY" .json)
  echo "Found session: $SESSION_ID"

  # Download manifest
  SESSION_DIR="$INBOX/$SESSION_ID"
  mkdir -p "$SESSION_DIR"

  MANIFEST_JSON=$(s3_signed_request "GET" "$KEY" "" "")
  echo "$MANIFEST_JSON" > "$SESSION_DIR/manifest.json"

  # Parse image list from manifest
  IMAGE_COUNT=$(echo "$MANIFEST_JSON" | jq -r '.images | length')
  echo "  $IMAGE_COUNT images"

  echo "$MANIFEST_JSON" | jq -r '.images[]' | while read -r IMAGE; do
    echo "  Downloading $IMAGE..."
    s3_signed_request "GET" "images/$IMAGE" "" "image/jpeg" > "$SESSION_DIR/$IMAGE"
  done

  # Delete from R2
  echo "  Cleaning up from R2..."
  s3_signed_request "DELETE" "$KEY" "" "" > /dev/null
  echo "$MANIFEST_JSON" | jq -r '.images[]' | while read -r IMAGE; do
    s3_signed_request "DELETE" "images/$IMAGE" "" "" > /dev/null
  done

  MANIFEST_COUNT=$((MANIFEST_COUNT + 1))
done

if [ "$MANIFEST_COUNT" -eq 0 ]; then
  echo "No new sessions found."
  exit 0
fi

echo ""
echo "Downloaded $MANIFEST_COUNT sessions. Triggering parser..."

# Trigger parser for each session
for SESSION_DIR in "$INBOX"/*/; do
  if [ -f "${SESSION_DIR}manifest.json" ]; then
    echo "Parsing: $(basename "$SESSION_DIR")"
    cmd -p "$SESSION_DIR" \
      --yolo --skip-onboarding --max-turns 30 2>&1 | tail -1
  fi
done

echo "Pull complete."
