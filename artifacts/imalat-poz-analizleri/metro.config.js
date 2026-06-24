const { getDefaultConfig } = require("expo/metro-config");
const path = require("path");

const workspaceRoot = path.resolve(__dirname, "../..");
const projectRoot = __dirname;

const config = getDefaultConfig(projectRoot);

config.watchFolders = [workspaceRoot];

config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, "node_modules"),
  path.resolve(workspaceRoot, "node_modules"),
  path.resolve(workspaceRoot, "node_modules/.pnpm/node_modules"),
];

const blockListRE = config.resolver.blockList;
const extraBlockList = [/[/\\]\.local[/\\]/];
config.resolver.blockList = Array.isArray(blockListRE)
  ? [...blockListRE, ...extraBlockList]
  : blockListRE
  ? [blockListRE, ...extraBlockList]
  : extraBlockList;

module.exports = config;
