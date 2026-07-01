# Diagram Capture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the mobile photo capture pipeline to transcribe hand-drawn diagrams (mind maps, flowcharts, system diagrams, sketches) into structured outputs (Obsidian Canvas, Mermaid, or image-link notes).

**Architecture:** The `akasha-mobile-parser` agent gains a classification step. Non-math images are routed to a new `akasha-diagram-parser` skill (`.commandcode/skills/`) that produces Canvas JSON, Mermaid syntax, or image-link notes. A new `bin/akasha-diagram-lint.js` script validates output before saving. Storage is unified under `_assets/`.

**Tech Stack:** Node.js (linter), JSON Canvas 1.0 (Obsidian), Mermaid.js syntax, existing Command Code pipeline

---

### Task 1: Create `_assets/` directory

**Files:**
- Create: `_assets/`
- Create: `_assets/.gitkeep`

- [ ] **Step 1: Create directory and gitkeep**

Create the `_assets/` directory in the vault root with a `.gitkeep` so it's tracked by git.

- [ ] **Step 2: Commit**

```bash
git add _assets/
git commit -m "feat: add _assets/ directory for original capture images"
```

---

### Task 2: Create akasha-diagram-parser skill — SKILL.md

**Files:**
- Create: `.commandcode/skills/akasha-diagram-parser/SKILL.md`
- Create: `.commandcode/skills/akasha-diagram-parser/references/`
- Create: `.commandcode/skills/akasha-diagram-parser/references/canvas/`
- Create: `.commandcode/skills/akasha-diagram-parser/references/mermaid/`
- Create: `.commandcode/skills/akasha-diagram-parser/references/validation/`

- [ ] **Step 1: Create directory structure**

Create the full directory tree for the skill.

- [ ] **Step 2: Write SKILL.md**

```markdown
---
name: akasha-diagram-parser
description: Parse handwritten diagram photos into structured outputs — Canvas JSON, Mermaid, or image-link notes. Use when the mobile parser or ingest agent encounters non-math image content.
---

# Akasha Diagram Parser

Transcribe handwritten diagrams from photos into structured formats.

## Classification Rubric

Given a photo of a notebook page, classify the content:

| Content type | Characteristics | Output format |
|---|---|---|
| Math | Equations, derivations, proofs with symbols | NOT handled here — pass to math path |
| Mind map / spatial | Central concept with branching nodes, free-form positioning | Canvas (.canvas) |
| Flowchart / process | Sequential steps, decision diamonds, labeled arrows | Mermaid (flowchart) |
| System architecture | Box-and-arrow layers, components, services | Canvas (.canvas) |
| Concept sketch | Freehand drawing of data structures, trees, graphs | Canvas (.canvas) |
| Annotated code | Written code with margin scribbles, arrows between lines | Image-link note |
| Mixed (math + diagram) | Both equations and a diagram on the same page | Canvas + math note with ![[.canvas]] embed |

If unsure, prefer Canvas over image-link. If image is completely unreadable, create image-link note with `> [!warning] Could not classify`.

## Workflow

1. **Classify** image content using the rubric above
2. **Select format** based on classification
3. **Read reference** from `references/` for the chosen format
4. **Generate** output following the reference spec
5. **Validate** output using validation rules
6. **If validation fails**, fall back to image-link note

## Output Specifications

### Canvas path
- Read `references/canvas/spec.md` for JSON Canvas 1.0 spec
- Read `references/canvas/examples.md` for mind map and system diagram examples
- Produce a valid `.canvas` file with text nodes, edges, group nodes as needed
- Include the original image as a file node in the canvas for reference
- Save `.canvas` alongside `.md` note
- The `.md` note embeds the canvas with `![[filename.canvas]]`
- Canvas files are NOT registered in `_moc-registry`

### Mermaid path
- Read `references/mermaid/flowchart.md` for flowchart syntax
- Read `references/mermaid/mindmap.md` for mind map syntax
- Read other `references/mermaid/*.md` files as needed for specific diagram types
- Produce a valid ` ```mermaid` code block for inclusion in the note body
- Use `flowchart TD` or `flowchart LR` for process/algorithm diagrams
- Use `mindmap` for hierarchical diagrams
- No separate file needed — Mermaid block goes directly in the `.md` body

### Image-link path (fallback)
- Create a `.md` concept note
- Do NOT embed the image (`![[image.jpg]]`)
- Instead, link to it: `[[_assets/session-id/image.jpg]]`
- Write a brief description of what the diagram shows
- Include frontmatter: type, domain, tags, image_source pointing to the file

## Validation

- Run `bin/akasha-diagram-lint.js <file>` after generating Canvas or Mermaid output
- If the linter exits with non-zero, fall back to image-link note
- If the output has many `[?]` markers or unreadable text, consider this low confidence

## Mixing with math

If the same image contains both math and a diagram:
1. Transcribe the math to LaTeX/markdown
2. Transcribe the diagram to Canvas
3. Create a `.md` note with the math content in the body
4. Embed the canvas at the natural break point: `![[diagram.canvas]]`
```

- [ ] **Step 3: Commit**

```bash
git add .commandcode/skills/akasha-diagram-parser/
git commit -m "feat: create akasha-diagram-parser skill structure"
```

---

### Task 3: Port Canvas references

**Files:**
- Create: `.commandcode/skills/akasha-diagram-parser/references/canvas/spec.md`
- Create: `.commandcode/skills/akasha-diagram-parser/references/canvas/examples.md`

- [ ] **Step 1: Copy json-canvas skill from reference-repo**

Source: `docs_and_references/reference-repos/obsidian-skills/skills/json-canvas/SKILL.md`
Target: `references/canvas/spec.md`
The skill file IS the spec — copy the full content (node/edge specs, ID gen, layout, validation).

- [ ] **Step 2: Copy Canvas examples from reference-repo**

Source: `docs_and_references/reference-repos/obsidian-skills/skills/json-canvas/references/EXAMPLES.md`
Target: `references/canvas/examples.md`
Copy the mind map, flowchart, and system diagram examples.

- [ ] **Step 3: Commit**

```bash
git add .commandcode/skills/akasha-diagram-parser/references/canvas/
git commit -m "feat: port json-canvas spec and examples"
```

---

### Task 4: Port Mermaid references (38 files)

**Files:**
- Create: `.commandcode/skills/akasha-diagram-parser/references/mermaid/*.md` (all 38 files)

- [ ] **Step 1: Copy all Mermaid reference files**

Copy the entire contents of `docs_and_references/mermaid_skill_references/mermaid-skill/.claude/skills/mermaid/references/` into `references/mermaid/`.

```bash
cp -r "docs_and_references/mermaid_skill_references/mermaid-skill/.claude/skills/mermaid/references/"* \
  ".commandcode/skills/akasha-diagram-parser/references/mermaid/"
```

- [ ] **Step 2: Add transcription context comments to key files**

For `flowchart.md`, prepend a comment:
```
%% TRANSCRIPTION CONTEXT: When transcribing a hand-drawn flowchart,
%% extract decision diamonds (diamond shapes), process boxes (rectangles),
%% and labeled arrows. Map to flowchart syntax using { } for decisions
%% and [ ] for processes. Preserve arrow labels as edge text.
```

For `mindmap.md`:
```
%% TRANSCRIPTION CONTEXT: Hand-drawn mind maps have a central node with
%% branching subtrees. Preserve the hierarchy. Use indentation to represent
%% depth. Extract all node text from handwriting.
```

For `entityRelationshipDiagram.md`:
```
%% TRANSCRIPTION CONTEXT: Category theory and database diagrams use
%% entity boxes with relationship lines. Extract entity names, attribute
%% names, and relationship cardinality (1:1, 1:N, N:M) from the drawing.
```

- [ ] **Step 3: Commit**

```bash
git add .commandcode/skills/akasha-diagram-parser/references/mermaid/
git commit -m "feat: port all 38 mermaid reference files"
```

---

### Task 5: Create validation reference docs

**Files:**
- Create: `.commandcode/skills/akasha-diagram-parser/references/validation/confidence-thresholds.md`
- Create: `.commandcode/skills/akasha-diagram-parser/references/validation/failure-patterns.md`

- [ ] **Step 1: Write confidence-thresholds.md**

```markdown
# Confidence Thresholds

## Canvas
- Node count < 3 → LOW (too sparse to represent a meaningful diagram)
- All node texts are empty or "[?]" → LOW
- More than 50% of nodes have "[?]" content → LOW
- All nodes at the same coordinates → LOW (failed to parse layout)
- Node count > 30 → FLAG (may be too dense, but still valid)

## Mermaid
- Fewer than 2 node declarations → LOW (not a real diagram)
- Edge references to non-existent node IDs → FAIL (linter will catch)
- All node labels are "[unreadable]" → LOW
- No diagram type declaration → FAIL

## General
- Vision LLM output contains "I cannot", "I'm unable", "cannot read" → FAIL
- Output is empty or whitespace-only → FAIL
- Output is valid but describes the image metadata instead of transcribing → LOW
```

- [ ] **Step 2: Write failure-patterns.md**

```markdown
# Failure Patterns

## Common garbage Canvas output
1. **Single giant node** — LLM puts all text into one node instead of splitting by bubble
2. **No edges** — LLM describes nodes but doesn't connect them
3. **All nodes at (0,0)** — LLM fails to extract positional layout
4. **Overlapping coordinates** — Multiple nodes at the same position
5. **Prose description disguised as Canvas** — LLM writes `{"nodes": [{"text": "This is a diagram showing..."}]}` in a single node
6. **Malformed IDs** — IDs that are not 16-char hex (will be caught by linter)

## Common garbage Mermaid output
1. **Wrong diagram type** — LLM uses `graph` instead of `flowchart`, or `sequence` instead of `sequenceDiagram`
2. **Inline text before diagram declaration** — Prose explanation before the ` ```mermaid` delimiter
3. **Unclosed brackets** — Node labels with `[` but no `]`, or `{` without `}`
4. **Special characters in labels** — Curly braces `{}` inside node texts (breaks Mermaid rendering)
5. **Nested code blocks** — ` ```mermaid` inside another code block
```

- [ ] **Step 3: Commit**

```bash
git add .commandcode/skills/akasha-diagram-parser/references/validation/
git commit -m "feat: add validation reference docs"
```

---

### Task 6: Create `bin/akasha-diagram-lint.js`

**Files:**
- Create: `bin/akasha-diagram-lint.js`

- [ ] **Step 1: Write the linter script**

```javascript
#!/usr/bin/env node

/**
 * Akasha Diagram Linter
 * Validates Canvas (.canvas) JSON and Mermaid syntax.
 * Usage: node bin/akasha-diagram-lint.js <file>
 * Exit code: 0 = valid, 1 = invalid
 */

const fs = require('fs');
const path = require('path');

const filePath = process.argv[2];
if (!filePath) {
  console.error('Usage: akasha-diagram-lint.js <file>');
  process.exit(1);
}

const ext = path.extname(filePath);
const content = fs.readFileSync(filePath, 'utf-8').trim();

if (ext === '.canvas') {
  lintCanvas(content);
} else if (ext === '.md' || ext === '.mmd') {
  lintMermaid(content);
} else {
  console.error(`Unknown extension: ${ext}`);
  process.exit(1);
}

function lintCanvas(json) {
  let canvas;
  try {
    canvas = JSON.parse(json);
  } catch (e) {
    console.error('FAIL: Invalid JSON —', e.message);
    process.exit(1);
  }

  if (!Array.isArray(canvas.nodes)) {
    console.error('FAIL: Missing "nodes" array');
    process.exit(1);
  }

  const VALID_TYPES = new Set(['text', 'file', 'link', 'group']);
  const VALID_COLORS = new Set(['1', '2', '3', '4', '5', '6']);
  const HEX_COLOR = /^#[0-9a-fA-F]{6}$/;
  const HEX_ID = /^[0-9a-f]{16}$/;

  const ids = new Set();
  const nodeIds = new Set();

  for (let i = 0; i < canvas.nodes.length; i++) {
    const node = canvas.nodes[i];
    const idx = `nodes[${i}]`;

    if (!node.id) { console.error(`FAIL: ${idx} missing "id"`); process.exit(1); }
    if (!HEX_ID.test(node.id)) { console.error(`FAIL: ${idx} id "${node.id}" is not 16-char hex`); process.exit(1); }
    if (ids.has(node.id)) { console.error(`FAIL: ${idx} duplicate id "${node.id}"`); process.exit(1); }
    ids.add(node.id);
    nodeIds.add(node.id);

    if (!VALID_TYPES.has(node.type)) { console.error(`FAIL: ${idx} invalid type "${node.type}"`); process.exit(1); }

    if (typeof node.x !== 'number' || typeof node.y !== 'number') {
      console.error(`FAIL: ${idx} missing or non-numeric x/y`);
      process.exit(1);
    }
    if (typeof node.width !== 'number' || typeof node.height !== 'number') {
      console.error(`FAIL: ${idx} missing or non-numeric width/height`);
      process.exit(1);
    }

    if (node.type === 'text' && (!node.text || !node.text.trim())) {
      console.error(`FAIL: ${idx} text node has empty text`);
      process.exit(1);
    }
    if (node.type === 'file' && !node.file) {
      console.error(`FAIL: ${idx} file node missing "file"`);
      process.exit(1);
    }
    if (node.type === 'link' && !node.url) {
      console.error(`FAIL: ${idx} link node missing "url"`);
      process.exit(1);
    }

    if (node.color && !VALID_COLORS.has(node.color) && !HEX_COLOR.test(node.color)) {
      console.error(`FAIL: ${idx} invalid color "${node.color}"`);
      process.exit(1);
    }
  }

  if (canvas.edges) {
    for (let i = 0; i < canvas.edges.length; i++) {
      const edge = canvas.edges[i];
      const idx = `edges[${i}]`;

      if (!edge.id) { console.error(`FAIL: ${idx} missing "id"`); process.exit(1); }
      if (!HEX_ID.test(edge.id)) { console.error(`FAIL: ${idx} id is not 16-char hex`); process.exit(1); }
      if (ids.has(edge.id)) { console.error(`FAIL: ${idx} duplicate id`); process.exit(1); }
      ids.add(edge.id);

      if (!edge.fromNode || !nodeIds.has(edge.fromNode)) {
        console.error(`FAIL: ${idx} fromNode "${edge.fromNode}" not found in nodes`);
        process.exit(1);
      }
      if (!edge.toNode || !nodeIds.has(edge.toNode)) {
        console.error(`FAIL: ${idx} toNode "${edge.toNode}" not found in nodes`);
        process.exit(1);
      }

      const validSides = new Set(['top', 'right', 'bottom', 'left']);
      const validEnds = new Set(['none', 'arrow']);
      if (edge.fromSide && !validSides.has(edge.fromSide)) { console.error(`FAIL: ${idx} invalid fromSide`); process.exit(1); }
      if (edge.toSide && !validSides.has(edge.toSide)) { console.error(`FAIL: ${idx} invalid toSide`); process.exit(1); }
      if (edge.fromEnd && !validEnds.has(edge.fromEnd)) { console.error(`FAIL: ${idx} invalid fromEnd`); process.exit(1); }
      if (edge.toEnd && !validEnds.has(edge.toEnd)) { console.error(`FAIL: ${idx} invalid toEnd`); process.exit(1); }
    }
  }

  console.log('PASS: Canvas is valid');
  process.exit(0);
}

function lintMermaid(content) {
  // Strip code block delimiters if present
  let code = content.replace(/^```mermaid\s*\n?/i, '').replace(/\n?```\s*$/i, '').trim();

  if (!code) {
    console.error('FAIL: Empty Mermaid content');
    process.exit(1);
  }

  // Check for diagram type declaration
  const validTypes = [
    'flowchart', 'sequenceDiagram', 'classDiagram', 'stateDiagram',
    'erDiagram', 'gantt', 'pie', 'mindmap', 'timeline', 'gitGraph',
    'quadrantChart', 'requirementDiagram', 'c4', 'sankey', 'xyChart',
    'block', 'packet', 'kanban', 'architecture', 'radar', 'treemap',
    'userJourney', 'zenuml', 'graph', 'gitgraph'
  ];
  const firstLine = code.split('\n')[0].trim();
  const typeMatch = validTypes.find(t => firstLine.startsWith(t));
  if (!typeMatch) {
    console.error(`FAIL: Unknown or missing diagram type declaration. First line: "${firstLine}"`);
    process.exit(1);
  }

  // Check balanced brackets, parens, braces
  delimiters: {
    const pairs = [
      { open: '[', close: ']' },
      { open: '(', close: ')' },
      { open: '{', close: '}' },
    ];
    for (const { open, close } of pairs) {
      let depth = 0;
      let inString = false;
      for (const ch of code) {
        if (ch === '"') inString = !inString;
        if (inString) continue;
        if (ch === open) depth++;
        if (ch === close) depth--;
        if (depth < 0) {
          console.error(`FAIL: Unbalanced "${close}" without "${open}"`);
          process.exit(1);
        }
      }
      if (depth !== 0) {
        console.error(`FAIL: Unbalanced "${open}" — ${depth} unclosed`);
        process.exit(1);
      }
    }
  }

  console.log('PASS: Mermaid syntax is structurally valid');
  process.exit(0);
}
```

- [ ] **Step 2: Make executable and test**

```bash
chmod +x bin/akasha-diagram-lint.js
```

Run on a valid canvas to verify:
```bash
echo '{"nodes":[{"id":"6f0ad84f44ce9c17","type":"text","x":0,"y":0,"width":200,"height":100,"text":"Hello"}]}' > /tmp/test-valid.canvas
node bin/akasha-diagram-lint.js /tmp/test-valid.canvas
# Expected: PASS: Canvas is valid
```

Run on invalid canvas:
```bash
echo '{"nodes":[]}' > /tmp/test-invalid.canvas
node bin/akasha-diagram-lint.js /tmp/test-invalid.canvas
# Expected: FAIL
```

- [ ] **Step 3: Commit**

```bash
git add bin/akasha-diagram-lint.js
git commit -m "feat: add diagram linter for Canvas JSON and Mermaid syntax"
```

---

### Task 7: Update `akasha-mobile-parser.md`

**Files:**
- Modify: `.commandcode/agents/akasha-mobile-parser.md`

- [ ] **Step 1: Modify the agent prompt to add classification and diagram routing**

Replace the current single-path prompt with the new multi-path version. Key changes:

1. Replace "Pass all images to the Vision LLM for LaTeX transcription" with classification step
2. Add diagram processing sub-flow that loads `akasha-diagram-parser` skill
3. Add multiple output paths (Canvas, Mermaid, image-link)
4. Add mixed content handling
5. Update `image_source` path from `StudyMaterials/inbox/` to `_assets/`
6. Update image move path from `StudyMaterials/inbox/` to `_assets/`

- [ ] **Step 2: Write a test capture to verify the pipeline end-to-end**

Create a test session directory with a mock manifest and diagram image to test the classification path:
```
StudyMaterials/inbox/test-diagram-session/
├── manifest.json
└── page-01.jpg   (hand-drawn flowchart)
```

Run the parser:
```bash
cmdc -p "Act as akasha-mobile-parser. Process the mobile capture session at StudyMaterials/inbox/test-diagram-session"
```

- [ ] **Step 3: Commit**

```bash
git add .commandcode/agents/akasha-mobile-parser.md
git commit -m "feat: update mobile parser with diagram classification and multi-format output"
```

---

### Task 8: Update `akasha-ingest.md`

**Files:**
- Modify: `.commandcode/agents/akasha-ingest.md`

- [ ] **Step 1: Align image storage path**

In the "Photo-to-LaTeX transcription sub-flow" section:
- Change `image_source` frontmatter from `Inbox/_processed/` to `_assets/`
- Change archive step from moving to `Inbox/_processed/` to moving to `_assets/<session-id>/`

In the "Archive the source" section:
- Add note: Image files go to `_assets/`, non-image files go to `Inbox/_processed/`

- [ ] **Step 2: Replace `[!figure]` approach with skill invocation**

Where the prompt currently says "Preserve diagrams as described figures using `> [!figure]` callout syntax", replace with:
"Classify the image content. If it contains a diagram (mind map, flowchart, system diagram), load the akasha-diagram-parser skill and follow its workflow instead of using the `[!figure]` callout approach."

- [ ] **Step 3: Commit**

```bash
git add .commandcode/agents/akasha-ingest.md
git commit -m "refactor: align ingest agent storage paths and replace figure callout with skill"
```

---

### Task 9: Update `raw-guard.sh` for `_assets/`

**Files:**
- Modify: `bin/raw-guard.sh` (if it exists and doesn't already cover `_assets/`)

- [ ] **Step 1: Check if raw-guard covers _assets/**

Check current `raw-guard.sh` content. If it denies writes to `Inbox/_processed/` but not `_assets/`, extend it to cover both.

- [ ] **Step 2: Commit (if changed)**

```bash
git add bin/raw-guard.sh
git commit -m "chore: extend raw-guard to cover _assets/ directory"
```

---

### Task 10: Verify full pipeline

- [ ] **Step 1: Run the linter on all existing .canvas files (none expected yet)**

```bash
find . -name "*.canvas" -exec node bin/akasha-diagram-lint.js {} \;
```

- [ ] **Step 2: Create a test flowchart session manually**

Create `StudyMaterials/inbox/test-flowchart/manifest.json`:
```json
{
  "domain": "cs",
  "mocs": ["dsa"],
  "timestamp": "2026-07-01T10:00:00Z",
  "images": ["flowchart.jpg"]
}
```

Place a hand-drawn flowchart image as `flowchart.jpg`.

- [ ] **Step 3: Run the parser on the test session**

```bash
cmdc -p "Act as akasha-mobile-parser. Process the mobile capture session at StudyMaterials/inbox/test-flowchart"
```

- [ ] **Step 4: Verify output files exist**

Check that:
- `Knowledge/cs/<flowchart-slug>.md` was created
- If Canvas path: `<flowchart-slug>.canvas` exists alongside
- If Mermaid path: `.md` body contains a ` ```mermaid ` block
- If image-link path: `.md` contains `[[_assets/.../image.jpg]]` link
- Original image moved to `_assets/`
- Frontmatter `image_source` points to `_assets/` path

- [ ] **Step 5: Run linter on output**

```bash
node bin/akasha-diagram-lint.js "Knowledge/cs/*.canvas"
```
