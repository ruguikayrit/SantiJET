const { getDefaultConfig } = require("expo/metro-config");
const path = require("path");

const workspaceRoot = path.resolve(__dirname, "../..");
const projectRoot = __dirname;

const config = getDefaultConfig(projectRoot);

config.resolver.assetExts = [...config.resolver.assetExts, "pdf"];

config.watchFolders = [workspaceRoot];

config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, "node_modules"),
  path.resolve(workspaceRoot, "node_modules"),
  path.resolve(workspaceRoot, "node_modules/.pnpm/node_modules"),
];

// Exclude internal Replit tool directories from Metro's file watcher.
// These directories can be deleted/recreated at any time and their absence
// causes an ENOENT crash in Metro's FallbackWatcher.
const blockListRE = config.resolver.blockList;
const extraBlockList = [
  /[/\\]\.local[/\\]/,
  /[/\\]\.replit[/\\]/,
];
config.resolver.blockList = Array.isArray(blockListRE)
  ? [...blockListRE, ...extraBlockList]
  : blockListRE
  ? [blockListRE, ...extraBlockList]
  : extraBlockList;

module.exports = config;
