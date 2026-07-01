#!/usr/bin/env bash
set -euo pipefail

# akasha-pull.sh — poll R2 for new capture manifests, download sessions to StudyMaterials/inbox/,
# delete from R2, and trigger akasha-material-parser.

VAULT_PATH="$(cd "$(dirname "$0")/.." && pwd)"
INBOX="$VAULT_PATH/StudyMaterials/inbox"

# Load credentials
if [ -f "$VAULT_PATH/.env" ]; then
  set -a; source "$VAULT_PATH/.env"; set +a
fi

# Verify env vars
: "${AKASHA_R2_ENDPOINT:?AKASHA_R2_ENDPOINT not set}"
: "${AKASHA_R2_BUCKET:?AKASHA_R2_BUCKET not set}"
: "${AKASHA_R2_ACCESS_KEY:?AKASHA_R2_ACCESS_KEY not set}"
: "${AKASHA_R2_SECRET_KEY:?AKASHA_R2_SECRET_KEY not set}"

# S3 signing function — generates AWS Signature v4 using Python for portable HMAC
function s3_signed_request() {
  local METHOD="$1"
  local OBJECT_KEY_IN="$2"
  local PAYLOAD_FILE="$3"
  local CONTENT_TYPE="${4:-application/json}"
  local OBJECT_KEY="$AKASHA_R2_BUCKET/$OBJECT_KEY_IN"

  local HOST="${AKASHA_R2_ENDPOINT#https://}"

  # Compute payload hash
  local PAYLOAD_HASH
  if [ -n "$PAYLOAD_FILE" ] && [ -f "$PAYLOAD_FILE" ]; then
    PAYLOAD_HASH=$(openssl dgst -sha256 "$PAYLOAD_FILE" | awk '{print $NF}')
  else
    PAYLOAD_HASH=$(echo -n "" | openssl dgst -sha256 | awk '{print $NF}')
  fi

  # Generate signature via Python
  local SIGNING_OUTPUT=$(python -c "
import hmac, hashlib
from datetime import datetime, timezone

access_key = '$AKASHA_R2_ACCESS_KEY'
secret_key = '$AKASHA_R2_SECRET_KEY'
method = '$METHOD'
object_key = '$OBJECT_KEY'
host = '$HOST'
content_hash = '$PAYLOAD_HASH'

now = datetime.now(timezone.utc)
date_short = now.strftime('%Y%m%d')
date_long = now.strftime('%Y%m%dT%H%M%SZ')
region = 'auto'
service = 's3'
canonical_headers = f'host:{host}\\nx-amz-content-sha256:{content_hash}\\nx-amz-date:{date_long}\\n'
signed_headers = 'host;x-amz-content-sha256;x-amz-date'
canonical_request = f'{method}\\n/{object_key}\\n\\n{canonical_headers}\\n{signed_headers}\\n{content_hash}'
canonical_hash = hashlib.sha256(canonical_request.encode()).hexdigest()
string_to_sign = f'AWS4-HMAC-SHA256\\n{date_long}\\n{date_short}/{region}/{service}/aws4_request\\n{canonical_hash}'
k_secret = f'AWS4{secret_key}'.encode()
k_date = hmac.new(k_secret, date_short.encode(), hashlib.sha256).digest()
k_region = hmac.new(k_date, region.encode(), hashlib.sha256).digest()
k_service = hmac.new(k_region, service.encode(), hashlib.sha256).digest()
k_signing = hmac.new(k_service, b'aws4_request', hashlib.sha256).digest()
signature = hmac.new(k_signing, string_to_sign.encode(), hashlib.sha256).hexdigest()
print(f'{date_long}\\n{signature}')
")

  local DATE_LONG=$(echo "$SIGNING_OUTPUT" | sed -n '1p')
  local SIGNATURE=$(echo "$SIGNING_OUTPUT" | sed -n '2p')
  local DATE_SHORT="${DATE_LONG:0:8}"

  curl -s -X "$METHOD" \
    -H "Host: $HOST" \
    -H "Content-Type: $CONTENT_TYPE" \
    -H "x-amz-content-sha256: $PAYLOAD_HASH" \
    -H "x-amz-date: $DATE_LONG" \
    -H "Authorization: AWS4-HMAC-SHA256 Credential=$AKASHA_R2_ACCESS_KEY/$DATE_SHORT/auto/s3/aws4_request,SignedHeaders=host;x-amz-content-sha256;x-amz-date,Signature=$SIGNATURE" \
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

# Parser model override (set AKASHA_PARSER_MODEL in .env to pin a specific model)
PARSER_MODEL_FLAG=""
if [ -n "${AKASHA_PARSER_MODEL:-}" ]; then
  PARSER_MODEL_FLAG="--model $AKASHA_PARSER_MODEL"
fi

for SESSION_DIR in "$INBOX"/*/; do
  if [ -f "${SESSION_DIR}manifest.json" ]; then
    echo "Parsing: $(basename "$SESSION_DIR") ${PARSER_MODEL_FLAG:+($AKASHA_PARSER_MODEL)}"
    # shellcheck disable=SC2086
    cmdc -p "Act as akasha-mobile-parser. Process the mobile capture session at $SESSION_DIR" \
      $PARSER_MODEL_FLAG \
      --yolo --skip-onboarding --max-turns 30 2>&1 | tail -1
  fi
done

echo "Pull complete."
