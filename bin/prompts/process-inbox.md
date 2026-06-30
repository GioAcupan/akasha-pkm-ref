# Process Inbox

You are processing the Inbox for the nightly Akasha pipeline.

1. List every file in Inbox/ (excluding Inbox/_processed/). Use glob to find all files: `Inbox/**` but exclude `Inbox/_processed/**`.
2. For each file found, delegate to the akasha-ingest agent to process that single item.
3. After all items are processed, report a summary:
   - Total items processed
   - Notes created (count + titles)
   - Notes updated (count + titles)
   - Domains touched
   - Any proposed new domains
   - MOC placements and cross-domain listings
   - Any split proposals (MOCs with 15+ notes)
   - Any contradictions flagged
4. If the Inbox is empty, report: "Inbox is empty — nothing to process."
5. Update Knowledge/_index.md after all items are filed.

Delegate one agent per item — run them sequentially, not in parallel, to avoid index conflicts.
