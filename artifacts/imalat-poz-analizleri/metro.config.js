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

// Exclude tool directories that may be deleted/recreated and crash Metro's watcher.
const blockListRE = config.resolver.blockList;
const extraBlockList = [
  /[/\\]\.local[/\\]/,
  /expo-print_tmp_/,
  /[/\\]node_modules[/\\].*_tmp_\d+/,
];
config.resolver.blockList = Array.isArray(blockListRE)
  ? [...blockListRE, ...extraBlockList]
  : blockListRE
  ? [blockListRE, ...extraBlockList]
  : extraBlockList;

module.exports = config;
