#!/usr/bin/env node

const fs = require('node:fs');
const path = require('node:path');

const version = process.argv[2];
const match = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/.exec(version ?? '');
if (!match) {
  throw new Error(`Expected a stable semantic version (major.minor.patch), got: ${version}`);
}

const [, majorText, minorText, patchText] = match;
const [major, minor, patch] = [majorText, minorText, patchText].map(Number);
if (major > 2099 || minor > 999 || patch > 999) {
  throw new Error('Version exceeds the supported Android versionCode mapping');
}

// Preserve Android's increasing integer versionCode while keeping versionName semver.
const versionCode = major * 1_000_000 + minor * 1_000 + patch + 1;
const pubspecPath = process.argv[3]
  ? path.resolve(process.argv[3])
  : path.join(__dirname, '..', 'cactus_pocket', 'pubspec.yaml');
const pubspec = fs.readFileSync(pubspecPath, 'utf8');
const updated = pubspec.replace(/^version: .*$/m, `version: ${version}+${versionCode}`);
if (updated === pubspec) {
  throw new Error(`Could not find the version field in ${pubspecPath}`);
}
fs.writeFileSync(pubspecPath, updated);
console.log(`Set Flutter version to ${version}+${versionCode}`);
