#!/usr/bin/env bash
set -euo pipefail

# akasha-sync-schema.sh — compile domain/MOC registry into akasha-schema.json and upload to R2.
# Reads Knowledge/_domains.md and each Knowledge/*/_moc-registry.md.

VAULT_PATH="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT="$VAULT_PATH/.akasha/akasha-schema.json"

# Verify env vars
: "${AKASHA_R2_ENDPOINT:?AKASHA_R2_ENDPOINT not set}"
: "${AKASHA_R2_BUCKET:?AKASHA_R2_BUCKET not set}"
: "${AKASHA_R2_ACCESS_KEY:?AKASHA_R2_ACCESS_KEY not set}"
: "${AKASHA_R2_SECRET_KEY:?AKASHA_R2_SECRET_KEY not set}"

# Ensure .akasha directory exists
mkdir -p "$VAULT_PATH/.akasha"

# Build the schema JSON
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo '{' > "$OUTPUT"
echo '  "version": 1,' >> "$OUTPUT"
echo "  \"generated\": \"$TIMESTAMP\"," >> "$OUTPUT"
echo '  "domains": [' >> "$OUTPUT"

FIRST_DOMAIN=true
while IFS='|' read -r _leading domain _rest; do
  # Skip header and separator lines
  [[ "$domain" =~ ^[[:space:]]*$ ]] && continue
  domain=$(echo "$domain" | xargs)
  [[ "$domain" == "Domain" ]] && continue
  [[ "$domain" == "---"* ]] && continue
  [[ -z "$domain" ]] && continue

  # Use domain name as label (table has no dedicated label column)
  label="$domain"

  # Build MOC list from the domain's _moc-registry.md
  mocs_json="[]"
  MOC_REGISTRY="$VAULT_PATH/Knowledge/$domain/_moc-registry.md"
  if [ -f "$MOC_REGISTRY" ]; then
    mocs_json=$(
      set +o pipefail
      cat "$MOC_REGISTRY" \
        | grep '^|' \
        | grep -v '^| MOC' \
        | grep -v '^|---' \
        | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); if($2!="") print $2}' \
        | while read -r moc_name; do
            moc_id=$(echo "$moc_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
            echo "    { \"id\": \"$moc_id\", \"label\": \"$moc_name\" }"
          done \
        | jq -s '.'
    )
    [ -z "$mocs_json" ] && mocs_json="[]"
  fi

  if [ "$FIRST_DOMAIN" = true ]; then
    FIRST_DOMAIN=false
  else
    echo '    ,' >> "$OUTPUT"
  fi

  echo "    {" >> "$OUTPUT"
  echo "      \"id\": \"$domain\"," >> "$OUTPUT"
  echo "      \"label\": \"$label\"," >> "$OUTPUT"
  echo "      \"mocs\": $mocs_json" >> "$OUTPUT"
  echo "    }" >> "$OUTPUT"

done < "$VAULT_PATH/Knowledge/_domains.md"

echo '' >> "$OUTPUT"
echo '  ]' >> "$OUTPUT"
echo '}' >> "$OUTPUT"

# Validate JSON
if ! jq empty "$OUTPUT" 2>/dev/null; then
  echo "Error: generated invalid JSON" >&2
  exit 1
fi

# Upload to R2 using S3-compatible API
# R2 requires signature v4; uses aws-cli-style curl with s3 protocol
DATE_SHORT=$(date -u +"%Y%m%d")
DATE_LONG=$(date -u +"%Y%m%dT%H%M%SZ")
REGION="auto"
SERVICE="s3"

# Create signing key
function hmac_sha256() {
  echo -n "$2" | openssl dgst -sha256 -hmac "$1" -binary
}

SECRET_KEY_HEX=$(echo -n "AWS4$AKASHA_R2_SECRET_KEY" | xxd -p -c 256)
DATE_KEY=$(hmac_sha256 "$SECRET_KEY_HEX" "$DATE_SHORT" | xxd -p -c 256)
REGION_KEY=$(hmac_sha256 "$DATE_KEY" "$REGION" | xxd -p -c 256)
SERVICE_KEY=$(hmac_sha256 "$REGION_KEY" "$SERVICE" | xxd -p -c 256)
SIGNING_KEY=$(hmac_sha256 "$SERVICE_KEY" "aws4_request" | xxd -p -c 256)

# Upload file
SCHEMA_CONTENT=$(cat "$OUTPUT")
CONTENT_TYPE="application/json"
PAYLOAD_HASH=$(echo -n "$SCHEMA_CONTENT" | openssl dgst -sha256 | cut -d' ' -f2)

CANONICAL_REQUEST="PUT\n/schema/akasha-schema.json\n\nhost:${AKASHA_R2_ENDPOINT#https://}\nx-amz-content-sha256:$PAYLOAD_HASH\nx-amz-date:$DATE_LONG\n\nhost;x-amz-content-sha256;x-amz-date\n$PAYLOAD_HASH"
STRING_TO_SIGN="AWS4-HMAC-SHA256\n$DATE_LONG\n$DATE_SHORT/$REGION/s3/aws4_request\n$(echo -ne "$CANONICAL_REQUEST" | openssl dgst -sha256 | cut -d' ' -f2)"
SIGNATURE=$(echo -ne "$STRING_TO_SIGN" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:$SIGNING_KEY" | cut -d' ' -f2)

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -X PUT \
  -H "Host: ${AKASHA_R2_ENDPOINT#https://}" \
  -H "Content-Type: $CONTENT_TYPE" \
  -H "x-amz-content-sha256: $PAYLOAD_HASH" \
  -H "x-amz-date: $DATE_LONG" \
  -H "Authorization: AWS4-HMAC-SHA256 Credential=$AKASHA_R2_ACCESS_KEY/$DATE_SHORT/$REGION/s3/aws4_request,SignedHeaders=host;x-amz-content-sha256;x-amz-date,Signature=$SIGNATURE" \
  --data-binary "@$OUTPUT" \
  "$AKASHA_R2_ENDPOINT/schema/akasha-schema.json")

if [ "$HTTP_CODE" != "200" ]; then
  echo "Error: upload failed with HTTP $HTTP_CODE" >&2
  exit 1
fi

echo "Schema synced to R2 ($TIMESTAMP)"
