# Mobile Capture — PKM Side Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the four PKM-side deliverables from the mobile capture contract: schema sync, R2 pull, push notifications, and a material-parser agent update that handles image-based capture sessions.

**Architecture:** Three new Bash scripts (`akasha-sync-schema.sh`, `akasha-pull.sh`, `akasha-notify.sh`) form the pipeline. `akasha-sync-schema.sh` reads the domain/MOC registries and uploads `akasha-schema.json` to R2 — it hooks into the existing nightly pipeline. `akasha-pull.sh` polls R2 for new capture manifests, downloads sessions to `StudyMaterials/inbox/`, and triggers the parser agent. `akasha-notify.sh` sends Expo push notifications on parse failure. The material-parser agent gets a new image-session codepath alongside its existing PDF codepath.

**Tech Stack:** Bash, curl (S3-compatible API), jq, Python (optional for R2 signature v4)

---

### Task 1: Schema Sync Script (`bin/akasha-sync-schema.sh`)

**Files:**
- Create: `bin/akasha-sync-schema.sh`
- Modify: `bin/akasha-nightly.sh` (add step before streak)

- [ ] **Step 1: Create the script**

```bash
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
while IFS='|' read -r domain raw_label _; do
  # Skip header and separator lines
  [[ "$domain" =~ ^[[:space:]]*$ ]] && continue
  domain=$(echo "$domain" | xargs)
  [[ "$domain" == "Domain" ]] && continue
  [[ "$domain" == "---"* ]] && continue
  [[ -z "$domain" ]] && continue

  # Extract label (second column)
  label=$(echo "$raw_label" | xargs)
  [[ -z "$label" ]] && label="$domain"

  # Build MOC list from the domain's _moc-registry.md
  mocs_json="[]"
  MOC_REGISTRY="$VAULT_PATH/Knowledge/$domain/_moc-registry.md"
  if [ -f "$MOC_REGISTRY" ]; then
    mocs_json=$(
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
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x bin/akasha-sync-schema.sh`
Expected: No output, exit code 0.

- [ ] **Step 3: Verify it parses the registry correctly (dry-run)**

Run: `bin/akasha-sync-schema.sh` (without R2 env vars — it should fail on the env check, proving it reached that point)
Expected: `AKASHA_R2_ENDPOINT not set` error.

Then set a dummy endpoint and check output:
```bash
export AKASHA_R2_ENDPOINT="http://localhost:9000"
export AKASHA_R2_BUCKET="test"
export AKASHA_R2_ACCESS_KEY="test"
export AKASHA_R2_SECRET_KEY="test"
# Skip actual upload — check generated file
head -c 500 .akasha/akasha-schema.json
```
Expected: Valid JSON with domains matching `Knowledge/_domains.md`.

- [ ] **Step 4: Hook into nightly pipeline**

Edit `bin/akasha-nightly.sh` to add a step before the current [1/4]:

```bash
# Edit: insert after "echo \"\"", before "# Step 1: Process inbox"
```

Change the step numbering so the pipeline becomes [1/5] through [5/5]:

```bash
# After:
echo "=== Akasha Nightly Pipeline ==="
echo ""

# Add:
echo "[1/5] Syncing schema to R2..."
if [ -f "$VAULT_PATH/bin/akasha-sync-schema.sh" ]; then
  bash "$VAULT_PATH/bin/akasha-sync-schema.sh" 2>&1 | tail -1
else
  echo "  (not yet implemented — Sprint 6+)"
fi
echo ""

# Then update all subsequent step numbers:
# [1/4] → [2/5]
# [2/4] → [3/5]
# [3/4] → [4/5]
# [4/4] → [5/5]
```

- [ ] **Step 5: Commit**

```bash
git add bin/akasha-sync-schema.sh bin/akasha-nightly.sh
git commit -m "feat: add akasha-sync-schema.sh — publish domain/MOC schema to R2"
```

---

### Task 2: Pull Script (`bin/akasha-pull.sh`)

**Files:**
- Create: `bin/akasha-pull.sh`

- [ ] **Step 1: Create the script**

```bash
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
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x bin/akasha-pull.sh`
Expected: No output, exit code 0.

- [ ] **Step 3: Verify dry-run without R2 credentials**

Run: `bin/akasha-pull.sh`
Expected: `AKASHA_R2_ENDPOINT not set` error (proves env guard works).

- [ ] **Step 4: Commit**

```bash
git add bin/akasha-pull.sh
git commit -m "feat: add akasha-pull.sh — poll R2 for capture sessions and trigger parser"
```

---

### Task 3: Notify Script (`bin/akasha-notify.sh`)

**Files:**
- Create: `bin/akasha-notify.sh`

- [ ] **Step 1: Create the script**

```bash
#!/usr/bin/env bash
set -euo pipefail

# akasha-notify.sh — send Expo push notification when a capture session fails parsing.
# Usage: akasha-notify.sh <session_id>

SESSION_ID="${1:-}"
if [ -z "$SESSION_ID" ]; then
  echo "Usage: akasha-notify.sh <session_id>" >&2
  exit 1
fi

: "${EXPO_PUSH_TOKEN:?EXPO_PUSH_TOKEN not set}"

curl -s -H "Content-Type: application/json" \
  -X POST "https://exp.host/--/api/v2/push/send" \
  -d "$(cat <<EOF
{
  "to": "$EXPO_PUSH_TOKEN",
  "title": "Akasha Alert: Parse Failed",
  "body": "Session '$SESSION_ID' could not be read. Please rescan.",
  "data": {
    "session_id": "$SESSION_ID",
    "type": "parse_failure"
  }
}
EOF
)"
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x bin/akasha-notify.sh`
Expected: No output, exit code 0.

- [ ] **Step 3: Verify usage error without arguments**

Run: `bin/akasha-notify.sh`
Expected: `Usage: akasha-notify.sh <session_id>` error.

- [ ] **Step 4: Verify env guard works**

Run: `bin/akasha-notify.sh test-session`
Expected: `EXPO_PUSH_TOKEN not set` error.

- [ ] **Step 5: Commit**

```bash
git add bin/akasha-notify.sh
git commit -m "feat: add akasha-notify.sh — Expo push notification on parse failure"
```

---

### Task 4: Update Material Parser Agent

**Files:**
- Modify: `.commandcode/agents/akasha-material-parser.md`

- [ ] **Step 1: Add image-session codepath to the agent prompt**

The agent currently only handles PDFs. Add an image-session detection step at the top of the Process section, between the existing section header and step 1.

Open `.commandcode/agents/akasha-material-parser.md` and insert after `## Process` and before `1. **Identify the PDF.**`:

```markdown
## Routing: PDF vs. Image Session

If the input is a directory path (not a filename), it is a mobile capture session. 
The directory contains `manifest.json` and one or more `.jpg` images.

**Image session workflow:**

1. Read `manifest.json` from the session directory. Extract: `domain`, `mocs`, `timestamp`, `images` array.

2. Pass all images to the local Vision LLM for LaTeX transcription. Use a single prompt that 
   instructs the model to produce one continuous LaTeX document merging all pages.

3. Validate the output:
   - Must contain valid LaTeX syntax (balanced `$$`, `{ }`, `\begin`/`\end`)
   - Must not contain the Vision LLM's refusal text ("I cannot", "I'm unable", "cannot read")
   - If validation fails: run `bash bin/akasha-notify.sh <session_id>` and stop

4. On success, create a math note at `Knowledge/<domain>/<title-slug>.md` using `Templates/math.md` 
   with these frontmatter values:
   - `type: math`
   - `title:` derive from the first meaningful line of LaTeX content (or use the session_id if unclear)
   - `status: seed`
   - `domain: <domain from manifest>`
   - `created: <timestamp from manifest>`
   - `updated: <timestamp from manifest>`
   - `tags: [<mocs from manifest, comma-separated>]`
   - `image_source: StudyMaterials/inbox/<session_id>/`
   - `sources: []`

5. Move the raw images to `_assets/<session_id>/` and commit.

6. Report: session_id, domain, mocs, generated note path, image count.

**PDF workflow (original):**
```

Then renumber the existing PDF steps to make it clear they follow the PDF routing. Change the existing step `1. **Identify the PDF.**` to `1. **Identify the PDF (PDF workflow only).**`.

- [ ] **Step 2: Update the description in the frontmatter**

Replace the existing description line:

```yaml
description: Extract table of contents from a PDF ebook, estimate per-chapter difficulty ...
```

With:

```yaml
description: Parse PDF ebooks into material notes, or process mobile capture image sessions into LaTeX math notes via Vision LLM.
```

- [ ] **Step 3: Commit**

```bash
git add .commandcode/agents/akasha-material-parser.md
git commit -m "feat: add image-session codepath to akasha-material-parser for mobile capture"
```

---

### Task 5: Add `.akasha/` to `.gitignore`

**Files:**
- Modify: `.gitignore` (create if absent)

- [ ] **Step 1: Ensure `.akasha/` is gitignored**

Check if `.gitignore` exists:
```bash
test -f .gitignore && echo "exists" || echo "not found"
```

If it doesn't exist, create it. Then add the line:

```
.akasha/akasha-schema.json
```

`akasha-schema.json` is a build artifact — it gets generated nightly and uploaded to R2. It should not be committed.

- [ ] **Step 2: Commit**

```bash
git add .gitignore
git commit -m "chore: gitignore generated akasha-schema.json"
```

---

### Task 6: End-to-End Dry-Run Validation

**Files:**
- None (verification only)

- [ ] **Step 1: Validate schema generation**

```bash
export AKASHA_R2_ENDPOINT="https://localhost:9000"
export AKASHA_R2_BUCKET="test"
export AKASHA_R2_ACCESS_KEY="test"
export AKASHA_R2_SECRET_KEY="test"
bash bin/akasha-sync-schema.sh
cat .akasha/akasha-schema.json | jq .
```

Expected: Valid JSON containing all 3 domains (math, cs, quant) with empty MOC arrays for each. The upload will fail (localhost) but the file generation should complete first.

- [ ] **Step 2: Verify no regressions in nightly pipeline**

Run: `grep -n "\[.*\/.*\]" bin/akasha-nightly.sh`
Expected: Steps should be numbered [1/5] through [5/5].

- [ ] **Step 3: Verify parser agent routes correctly**

Read the modified agent file and confirm:
```bash
grep -n "Routing: PDF vs" .commandcode/agents/akasha-material-parser.md
grep -n "Image session workflow" .commandcode/agents/akasha-material-parser.md
grep -n "PDF workflow (original)" .commandcode/agents/akasha-material-parser.md
```
Expected: All three found.

---

### Task 7: Update Contract Version

**Files:**
- Modify: `docs/mobile-capture-contract.md`

- [ ] **Step 1: Bump the contract version table**

Edit the version table at the bottom of the contract. Replace:

```markdown
| Contract Version | Schema Version | Changes |
|-----------------|----------------|---------|
| 1.0.0 | 1 | Initial release |
```

With:

```markdown
| Contract Version | Schema Version | Changes |
|-----------------|----------------|---------|
| 1.0.0 | 1 | Initial release |
| 1.0.1 | 1 | PKM-side implementation complete: sync/pull/notify scripts + parser agent update |
```

- [ ] **Step 2: Add final checklist to the contract**

At the bottom of the contract, after the compatibility rule, append:

```markdown
## 6. Implementation Checklist (PKM Side)

- [x] `bin/akasha-sync-schema.sh` — schema generation + R2 upload
- [x] `bin/akasha-pull.sh` — R2 polling + session download + parser trigger
- [x] `bin/akasha-notify.sh` — Expo push notification on parse failure
- [x] `.commandcode/agents/akasha-material-parser.md` — image-session codepath
- [ ] R2 bucket created and credentials set in `.env`
- [ ] `EXPO_PUSH_TOKEN` set in `.env`
- [ ] `akasha-pull.sh` scheduled (cron/systemd timer)
```

- [ ] **Step 3: Commit**

```bash
git add docs/mobile-capture-contract.md
git commit -m "docs: bump mobile-capture-contract to 1.0.1, PKM side implemented"
```

---

### Task 8: User Setup (Manual Steps)

These are checkboxes for you (the user) to complete after the code is in place. They require external services.

- [ ] Create Cloudflare R2 bucket
- [ ] Generate R2 API token with read/write access
- [ ] Add to `~/.akasha.env`:
  ```bash
  AKASHA_R2_ENDPOINT=https://<account>.r2.cloudflarestorage.com/<bucket>
  AKASHA_R2_BUCKET=<bucket-name>
  AKASHA_R2_ACCESS_KEY=<access-key-id>
  AKASHA_R2_SECRET_KEY=<secret-access-key>
  ```
- [ ] Source env in nightly script (add `source ~/.akasha.env` at the top of `bin/akasha-nightly.sh` after the VAULT_PATH line)
- [ ] Install Expo Go on the mobile device and register for push notifications
- [ ] Add `EXPO_PUSH_TOKEN` to `~/.akasha.env`
- [ ] Schedule `bin/akasha-pull.sh` (cron: `*/5 * * * *` or systemd timer)
