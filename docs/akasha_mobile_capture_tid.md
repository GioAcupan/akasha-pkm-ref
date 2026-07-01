# Technical Idea Document (TID): Akasha Mobile Capture

**Status:** Draft

**Date:** June 30, 2026

**Target Architecture:** Expo (React Native) + Cloudflare R2 + Local Daemon

## 1. Abstract

The Akasha PKM currently lacks a frictionless capture rail for physical, handwritten materials (especially theoretical math and proofs).

This document outlines the architecture for a companion mobile app that acts as an intelligent "remote sensor" for the PKM. The app handles document scanning, image enhancement, and metadata tagging (syncing with the repo's schema), then batches and offloads the data to a temporary cloud bucket. The local `akasha-pkm` daemon picks up this payload, executes local Vision LLM processing to generate LaTeX markdown, and sends a push notification back to the device if the scan fails.

## 2. The Mobile App (The "Smart Sensor")

The frontend will be built using **Expo (React Native)**. It is designed to be an offline-first capture tool requiring fewer than three taps to complete a workflow.

### 2.1 Core Capabilities

- **Document Scanning:** Utilizes `react-native-document-scanner-plugin` to automatically detect page edges, correct perspective, and apply an adaptive B&W threshold. This reduces image size to ~100KB while maximizing text contrast for the Vision LLM.

- **Session Mode:** Allows users to snap multiple pages in sequence. These images are bundled into a single `session_id` to be processed as a continuous Markdown document.

- **Offline Local Queue:** Captures are saved to an Expo SQLite "Outbox". Uploads automatically trigger via `expo-background-fetch` when a stable Wi-Fi or cellular connection is re-established.

- **Dynamic Tagging:** The app fetches a lightweight `akasha-schema.json` from the cloud. This populates a fast autocomplete UI allowing the user to select the correct **Domain** (e.g., `math`) and **MOC** (e.g., `linear-algebra`) before saving to the Outbox.

## 3. The Cloud Bridge (The "Dumb Pipe")

To avoid bloating the Git repository with binary blobs and to bypass complex mobile-to-Git authentication, the system uses a serverless intermediary.

- **Storage:** **Cloudflare R2** (S3-Compatible). The app uploads the optimized images alongside a structured JSON payload containing the metadata.

- **Payload Structure Example:**
  
  ```
  {
    "session_id": "math_proof_8492",
    "timestamp": "2026-06-30T21:05:00Z",
    "images": ["url_1.jpg", "url_2.jpg"],
    "domain": "math",
    "mocs": ["calculus", "optimization"]
  }
  ```

## 4. Required Changes to `akasha-pkm-ref`

For the mobile app to function as designed, the existing PKM repository and local daemon environment must be updated.

### 4.1 Schema Sync Hook (`bin/akasha-sync-schema.sh`)

**Need:** The mobile app needs to know what tags exist without parsing the entire Git repository.

**Action:** Create a script that runs via your `auto-commit.sh` or `akasha-nightly.sh`. It must:

1. Grep the `Knowledge/_domains.md` and `_moc-registry.md` files.

2. Compile a list of all active Domains and MOCs into `akasha-schema.json`.

3. Upload `akasha-schema.json` to the Cloudflare R2 bucket.

### 4.2 Ingestion Poller (`bin/akasha-pull.sh`)

**Need:** The local machine needs to know when new scans arrive in the cloud bucket.

**Action:** Create a lightweight Bash/Python script that runs periodically (or listens via Cloudflare Tunnel/ngrok).

1. Scans the R2 bucket for new JSON payloads.

2. Downloads the JSON and associated images to a local `StudyMaterials/inbox/` directory.

3. Deletes the items from the R2 bucket to maintain zero cloud state.

4. Triggers the `akasha-material-parser`.

### 4.3 Agent Updates (`.commandcode/agents/akasha-material-parser.md`)

**Need:** The parser must be aware of multi-image sessions and inject metadata.

**Action:** Update the parser's prompt logic to:

1. Accept an array of images (for Session Mode).

2. Read the `domain` and `mocs` from the JSON payload.

3. Automatically inject those exact strings into the YAML frontmatter of the newly generated `Templates/math.md` file.

### 4.4 Push Notification Script (`bin/akasha-notify.sh`)

**Need:** The system must alert the user if the local Vision LLM hallucinates or returns a low-confidence LaTeX extraction due to a blurry photo.

**Action:**

1. Add an `EXPO_PUSH_TOKEN` variable to your local `.env` file.

2. Create `bin/akasha-notify.sh` using `curl` to hit the Expo Push API:
   
   ```
   curl -H "Content-Type: application/json" -X POST "[https://exp.host/--/api/v2/push/send](https://exp.host/--/api/v2/push/send)" -d '{
    "to": "'$EXPO_PUSH_TOKEN'",
    "title": "Akasha Alert: Parse Failed",
    "body": "Session '$1' could not be read. Please rescan."
   }'
   ```

3. Update `akasha-material-parser.md` to execute this script if the LLM output fails syntax linting.

## 5. End-to-End Workflow

1. **Capture:** User opens app, selects "Math" and "Linear Algebra". Snaps 3 pages of a proof.

2. **Queue:** App saves images to SQLite.

3. **Upload:** App detects Wi-Fi, uploads 3 images + 1 JSON file to Cloudflare R2.

4. **Pull:** Local laptop's `akasha-pull.sh` detects new files, downloads them to local `/inbox`, and deletes from R2.

5. **Parse:** `akasha-material-parser.md` passes the 3 images to the local Vision LLM.

6. **Evaluate:**
   
   - *If Success:* Generates a beautifully formatted LaTeX markdown file, moves the raw images to `_assets/`, and auto-commits.
   
   - *If Failure:* Triggers `akasha-notify.sh`. User receives a push notification on their phone 5 seconds later requesting a rescan.
