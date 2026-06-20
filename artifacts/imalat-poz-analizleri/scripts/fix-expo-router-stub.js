#!/usr/bin/env node
/**
 * This script fixes the expo-router symlink created by pnpm.
 * pnpm creates node_modules/expo-router as a symlink to the pnpm virtual store
 * (a very long path with @ and + chars). Expo CLI resolves this via realpathSync,
 * producing a mainModuleName with special characters that the Replit proxy cannot route.
 * We replace the symlink with a real directory containing a stub entry.js.
 */
const fs = require('fs');
const path = require('path');

const artifactDir = path.resolve(__dirname, '..');
const stubDir = path.join(artifactDir, 'node_modules', 'expo-router');
const stubEntry = path.join(stubDir, 'entry.js');
const stubPkg = path.join(stubDir, 'package.json');

// Find the real expo-router entry in pnpm private hoist
const realEntryPaths = [
  path.join(artifactDir, '../../node_modules/.pnpm/node_modules/expo-router/entry.js'),
];

let realEntry = realEntryPaths.find(p => {
  try { return fs.existsSync(fs.realpathSync(p)); } catch { return false; }
});

if (!realEntry) {
  console.log('[fix-expo-router-stub] Could not find real expo-router entry, skipping.');
  process.exit(0);
}
realEntry = fs.realpathSync(realEntry);

// Check if stub already correctly set up
if (!fs.existsSync(stubDir) || fs.lstatSync(stubDir).isSymbolicLink()) {
  // Remove symlink if present
  if (fs.existsSync(stubDir) || fs.lstatSync(stubDir).isSymbolicLink()) {
    fs.rmSync(stubDir, { recursive: true, force: true });
  }
  fs.mkdirSync(stubDir, { recursive: true });
}

// Write stub files.
// - main: points to real build/index.js so `import { Stack } from "expo-router"` works
// - types: points to real declarations for TypeScript
// - entry.js stays in stub so `expo-router/entry` (the app entry) still resolves here
const realPkgDir = path.dirname(realEntry);
const mainRelPath  = path.relative(stubDir, path.join(realPkgDir, 'build/index.js'));
const typesRelPath = path.relative(stubDir, path.join(realPkgDir, 'build/index.d.ts'));
fs.writeFileSync(stubPkg, JSON.stringify({
  name: 'expo-router',
  version: '6.0.23',
  main: mainRelPath,
  types: typesRelPath,
}, null, 2));

fs.writeFileSync(stubEntry, `import '${realEntry}';\n`);

console.log('[fix-expo-router-stub] Stub created at', stubDir);
console.log('[fix-expo-router-stub] -> entry:', realEntry);
