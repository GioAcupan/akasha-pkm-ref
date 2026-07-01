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
  console.error('Unknown extension: ' + ext);
  process.exit(1);
}

function lintCanvas(json) {
  let canvas;
  try {
    canvas = JSON.parse(json);
  } catch (e) {
    console.error('FAIL: Invalid JSON - ' + e.message);
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
    const idx = 'nodes[' + i + ']';

    if (!node.id) { console.error('FAIL: ' + idx + ' missing "id"'); process.exit(1); }
    if (!HEX_ID.test(node.id)) { console.error('FAIL: ' + idx + ' id "' + node.id + '" is not 16-char hex'); process.exit(1); }
    if (ids.has(node.id)) { console.error('FAIL: ' + idx + ' duplicate id "' + node.id + '"'); process.exit(1); }
    ids.add(node.id);
    nodeIds.add(node.id);

    if (!VALID_TYPES.has(node.type)) { console.error('FAIL: ' + idx + ' invalid type "' + node.type + '"'); process.exit(1); }

    if (typeof node.x !== 'number' || typeof node.y !== 'number') {
      console.error('FAIL: ' + idx + ' missing or non-numeric x/y');
      process.exit(1);
    }
    if (typeof node.width !== 'number' || typeof node.height !== 'number') {
      console.error('FAIL: ' + idx + ' missing or non-numeric width/height');
      process.exit(1);
    }

    if (node.type === 'text' && (!node.text || !node.text.trim())) {
      console.error('FAIL: ' + idx + ' text node has empty text');
      process.exit(1);
    }
    if (node.type === 'file' && !node.file) {
      console.error('FAIL: ' + idx + ' file node missing "file"');
      process.exit(1);
    }
    if (node.type === 'link' && !node.url) {
      console.error('FAIL: ' + idx + ' link node missing "url"');
      process.exit(1);
    }

    if (node.color && !VALID_COLORS.has(node.color) && !HEX_COLOR.test(node.color)) {
      console.error('FAIL: ' + idx + ' invalid color "' + node.color + '"');
      process.exit(1);
    }
  }

  if (canvas.edges) {
    for (let i = 0; i < canvas.edges.length; i++) {
      const edge = canvas.edges[i];
      const idx = 'edges[' + i + ']';

      if (!edge.id) { console.error('FAIL: ' + idx + ' missing "id"'); process.exit(1); }
      if (!HEX_ID.test(edge.id)) { console.error('FAIL: ' + idx + ' id is not 16-char hex'); process.exit(1); }
      if (ids.has(edge.id)) { console.error('FAIL: ' + idx + ' duplicate id'); process.exit(1); }
      ids.add(edge.id);

      if (!edge.fromNode || !nodeIds.has(edge.fromNode)) {
        console.error('FAIL: ' + idx + ' fromNode "' + edge.fromNode + '" not found in nodes');
        process.exit(1);
      }
      if (!edge.toNode || !nodeIds.has(edge.toNode)) {
        console.error('FAIL: ' + idx + ' toNode "' + edge.toNode + '" not found in nodes');
        process.exit(1);
      }

      const validSides = new Set(['top', 'right', 'bottom', 'left']);
      const validEnds = new Set(['none', 'arrow']);
      if (edge.fromSide && !validSides.has(edge.fromSide)) { console.error('FAIL: ' + idx + ' invalid fromSide'); process.exit(1); }
      if (edge.toSide && !validSides.has(edge.toSide)) { console.error('FAIL: ' + idx + ' invalid toSide'); process.exit(1); }
      if (edge.fromEnd && !validEnds.has(edge.fromEnd)) { console.error('FAIL: ' + idx + ' invalid fromEnd'); process.exit(1); }
      if (edge.toEnd && !validEnds.has(edge.toEnd)) { console.error('FAIL: ' + idx + ' invalid toEnd'); process.exit(1); }
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
    console.error('FAIL: Unknown or missing diagram type declaration. First line: "' + firstLine + '"');
    process.exit(1);
  }

  // Check balanced brackets, parens, braces
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
        console.error('FAIL: Unbalanced "' + close + '" without "' + open + '"');
        process.exit(1);
      }
    }
    if (depth !== 0) {
      console.error('FAIL: Unbalanced "' + open + '" - ' + depth + ' unclosed');
      process.exit(1);
    }
  }

  console.log('PASS: Mermaid syntax is structurally valid');
  process.exit(0);
}
