#!/usr/bin/env node
/*
 * abi-drift.mjs -- check this binding's constants against the spec.
 *
 * A binding written in Zig cannot @cImport wasmcart.h in a freestanding wasm
 * build, so every constant in wasmcart.zig is a hand transcription, and a
 * transcription drifts. It happened: wasmcart 0.16.0 merged the WebSocket and
 * data-channel flags into one peer flag, and this module still declared
 * FLAG_NET_WS and FLAG_NET_DC afterwards. Nothing broke, because the surviving
 * flag kept the same bit, but the module named a flag the spec no longer had.
 *
 * The comptime block in wasmcart.zig catches a struct whose SIZE or field
 * OFFSET is wrong. It cannot catch a constant whose VALUE is wrong, because it
 * only compares the module against itself. This compares it against src/abi.js
 * in the wasmcart repo, which is the machine-readable source of truth the host
 * itself reads.
 *
 *   node tools/abi-drift.mjs [--wasmcart <path-to-wasmcart-checkout>]
 *
 * Resolution order for the spec: --wasmcart, $WASMCART_DIR, the installed
 * `wasmcart` package, then ../wasmcart. Skips with a clear message if none
 * resolve, so the check never fails a machine that simply lacks a checkout.
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(HERE, '..');

function specDir() {
  const i = process.argv.indexOf('--wasmcart');
  if (i >= 0 && process.argv[i + 1]) return process.argv[i + 1];
  if (process.env.WASMCART_DIR) return process.env.WASMCART_DIR;
  try {
    return path.dirname(fileURLToPath(import.meta.resolve('wasmcart')));
  } catch { /* not installed */ }
  return path.join(ROOT, '..', 'wasmcart');
}

const dir = specDir();
let abi;
try {
  abi = await import(path.join(dir, 'src', 'abi.js'));
} catch {
  console.log(`skip  abi-drift   no wasmcart checkout at ${dir}`);
  console.log('      pass --wasmcart <path>, set WASMCART_DIR, or npm i wasmcart');
  process.exit(0);
}

const src = readFileSync(path.join(ROOT, 'wasmcart.zig'), 'utf8');

/* Read `pub const NAME: <type> = <expr>;` and evaluate the shift form this
 * module uses. Deliberately not a full Zig parser: anything it cannot read is
 * reported as unreadable rather than silently skipped. */
function zigConst(name) {
  // The type annotation is optional in Zig, and this module uses both forms:
  // `pub const FLAG_DEBUG: u32 = 1 << 5;` but `pub const PAD_SIZE = 16;`.
  const m = src.match(new RegExp(`pub const ${name}\\s*(?::\\s*[a-z0-9]+\\s*)?=\\s*([^;]+);`));
  if (!m) return undefined;
  const e = m[1].trim();
  const shift = e.match(/^1\s*<<\s*(\d+)$/);
  if (shift) return 1 << Number(shift[1]);
  if (/^\d+$/.test(e)) return Number(e);
  return NaN;   // present but not in a form we read
}

/* spec name -> zig name */
const CONSTS = {
  ABI_VERSION: 'ABI_VERSION',
  FLAG_AUDIO_F32: 'FLAG_AUDIO_F32',
  FLAG_NET_PEER: 'FLAG_NET_PEER',
  FLAG_POINTER: 'FLAG_POINTER',
  FLAG_KEYBOARD: 'FLAG_KEYBOARD',
  FLAG_DEBUG: 'FLAG_DEBUG',
  FLAG_DETERMINISTIC: 'FLAG_DETERMINISTIC',
  GPU_API_NONE: 'GPU_API_NONE',
  GPU_API_WEBGL2: 'GPU_API_WEBGL2',
  PAD_SIZE: 'PAD_SIZE',
  POINTER_SIZE: 'POINTER_SIZE',
  DEBUG_FIELD_SIZE: 'DEBUG_FIELD_SIZE',
};

/* Names the spec has RETIRED. A binding that still declares one is telling its
 * users about a flag that no longer exists, which is the drift that prompted
 * this script. */
const RETIRED = ['FLAG_NET_WS', 'FLAG_NET_DC'];

const problems = [];
let checked = 0;

for (const [specName, zigName] of Object.entries(CONSTS)) {
  const want = abi[specName];
  if (want === undefined) continue;      // spec does not define it; nothing to check
  const got = zigConst(zigName);
  if (got === undefined) {
    problems.push(`${zigName} is missing; spec has ${specName} = ${want}`);
  } else if (Number.isNaN(got)) {
    problems.push(`${zigName} is not in a form this check can read`);
  } else if (got !== want) {
    problems.push(`${zigName} = ${got}, spec says ${want}`);
  } else {
    checked++;
  }
}

for (const dead of RETIRED) {
  if (zigConst(dead) !== undefined) {
    problems.push(`${dead} is retired from the spec but still declared here`);
  }
}

/* WcInfo field order. The comptime block asserts a few offsets against
 * literals; this ties the whole field list to the spec. */
const order = [
  'version', 'width', 'height', 'fb_ptr', 'audio_ptr', 'audio_cap',
  'audio_write_ptr', 'input_ptr', 'save_ptr', 'save_size', 'time_ptr',
  'host_info_ptr', 'flags', 'audio_sample_rate', 'pointer_ptr', 'keys_ptr',
  'gpu_api',
];
const body = src.match(/pub const WcInfo\s*=\s*extern struct\s*\{([^}]*)\}/s);
if (!body) {
  problems.push('could not find `pub const WcInfo` to check field order');
} else {
  const fields = [...body[1].matchAll(/^\s{4}([a-z_0-9]+)\s*:/gm)].map((m) => m[1]);
  if (abi.INFO_FIELDS_V3) {
    for (const [specField, off] of Object.entries(abi.INFO_FIELDS_V3)) {
      const name = specField.toLowerCase();
      const idx = fields.indexOf(name);
      if (idx < 0) { problems.push(`WcInfo is missing field ${name}`); continue; }
      if (idx * 4 !== off) {
        problems.push(`WcInfo.${name} is at byte ${idx * 4}, spec says ${off}`);
      } else checked++;
    }
  }
  if (fields.join(',') !== order.join(',')) {
    problems.push(`WcInfo field order differs from the spec:\n    got  ${fields.join(' ')}\n    want ${order.join(' ')}`);
  } else checked++;
}

/* The template ships its own copy of the module, so drift there is drift too.
 * test.sh already cmp's them; this reports it in the same voice as the rest. */
try {
  const tpl = readFileSync(path.join(ROOT, 'template', 'src', 'wasmcart.zig'), 'utf8');
  if (tpl !== src) problems.push('template/src/wasmcart.zig has drifted from wasmcart.zig');
  else checked++;
} catch {
  problems.push('template/src/wasmcart.zig is missing');
}

if (problems.length) {
  console.error(`FAIL  abi-drift   ${problems.length} problem(s) against ${dir}`);
  for (const p of problems) console.error(`      ${p}`);
  process.exit(1);
}
console.log(`ok    abi-drift    ${checked} constants match the spec at ${dir}`);
