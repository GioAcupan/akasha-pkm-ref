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

DOMAINS_JSON=""  # Accumulate domain JSON objects, comma-separated
while IFS='|' read -r _leading domain folder description _rest; do
  # Skip header and separator lines
  [[ "$domain" =~ ^[[:space:]]*$ ]] && continue
  domain=$(echo "$domain" | xargs)
  description=$(echo "$description" | xargs)
  [[ "$domain" == "Domain" ]] && continue
  [[ "$domain" == "---"* ]] && continue
  [[ -z "$domain" ]] && continue

  # Use description as label, fall back to domain name
  label="${description:-$domain}"

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

  if [ -n "$DOMAINS_JSON" ]; then
    DOMAINS_JSON="${DOMAINS_JSON},
"
  fi
  DOMAINS_JSON="${DOMAINS_JSON}    {
      \"id\": \"$domain\",
      \"label\": \"$label\",
      \"mocs\": $mocs_json
    }"
done < "$VAULT_PATH/Knowledge/_domains.md"

# Write the JSON
echo '{' > "$OUTPUT"
echo '  "version": 1,' >> "$OUTPUT"
echo "  \"generated\": \"$TIMESTAMP\"," >> "$OUTPUT"
echo '  "domains": [' >> "$OUTPUT"
echo "$DOMAINS_JSON" >> "$OUTPUT"
echo '  ]' >> "$OUTPUT"
echo '}' >> "$OUTPUT"

# Validate JSON
if ! jq empty "$OUTPUT" 2>/dev/null; then
  echo "Error: generated invalid JSON" >&2
  exit 1
fi

# Upload to R2 using S3-compatible API with AWS Signature v4
# Uses Python for reliable HMAC signing (portable across Windows/Linux/macOS)
CONTENT_TYPE="application/json"
OBJECT_KEY="$AKASHA_R2_BUCKET/schema/akasha-schema.json"
HOST="${AKASHA_R2_ENDPOINT#https://}"

# Hash the raw file (not via variable, which strips trailing newlines)
PAYLOAD_HASH=$(openssl dgst -sha256 "$OUTPUT" | awk '{print $NF}')

# Generate date + signature via Python
SIGNING_OUTPUT=$(python -c "
import hmac, hashlib
from datetime import datetime, timezone

access_key = '$AKASHA_R2_ACCESS_KEY'
secret_key = '$AKASHA_R2_SECRET_KEY'
bucket = '$AKASHA_R2_BUCKET'
content_hash = '$PAYLOAD_HASH'

now = datetime.now(timezone.utc)
date_short = now.strftime('%Y%m%d')
date_long = now.strftime('%Y%m%dT%H%M%SZ')
host = '$HOST'
region = 'auto'
service = 's3'
object_key = f'{bucket}/schema/akasha-schema.json'
canonical_headers = f'host:{host}\\nx-amz-content-sha256:{content_hash}\\nx-amz-date:{date_long}\\n'
signed_headers = 'host;x-amz-content-sha256;x-amz-date'
canonical_request = f'PUT\\n/{object_key}\\n\\n{canonical_headers}\\n{signed_headers}\\n{content_hash}'
canonical_hash = hashlib.sha256(canonical_request.encode()).hexdigest()
string_to_sign = f'AWS4-HMAC-SHA256\\n{date_long}\\n{date_short}/auto/s3/aws4_request\\n{canonical_hash}'
k_secret = f'AWS4{secret_key}'.encode()
k_date = hmac.new(k_secret, date_short.encode(), hashlib.sha256).digest()
k_region = hmac.new(k_date, region.encode(), hashlib.sha256).digest()
k_service = hmac.new(k_region, service.encode(), hashlib.sha256).digest()
k_signing = hmac.new(k_service, b'aws4_request', hashlib.sha256).digest()
signature = hmac.new(k_signing, string_to_sign.encode(), hashlib.sha256).hexdigest()
print(f'{date_short}\\n{date_long}\\n{signature}')
")

DATE_SHORT=$(echo "$SIGNING_OUTPUT" | sed -n '1p')
DATE_LONG=$(echo "$SIGNING_OUTPUT" | sed -n '2p')
SIGNATURE=$(echo "$SIGNING_OUTPUT" | sed -n '3p')

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -X PUT \
  -H "Host: $HOST" \
  -H "Content-Type: $CONTENT_TYPE" \
  -H "x-amz-content-sha256: $PAYLOAD_HASH" \
  -H "x-amz-date: $DATE_LONG" \
  -H "Authorization: AWS4-HMAC-SHA256 Credential=$AKASHA_R2_ACCESS_KEY/$DATE_SHORT/auto/s3/aws4_request,SignedHeaders=host;x-amz-content-sha256;x-amz-date,Signature=$SIGNATURE" \
  --data-binary "@$OUTPUT" \
  "$AKASHA_R2_ENDPOINT/$OBJECT_KEY")

if [ "$HTTP_CODE" != "200" ]; then
  echo "Error: upload failed with HTTP $HTTP_CODE" >&2
  exit 1
fi

echo "Schema synced to R2 ($TIMESTAMP)"
