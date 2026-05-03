const { getDefaultConfig } = require("expo/metro-config");
const path = require("path");
const fs = require("fs");

const workspaceRoot = path.resolve(__dirname, "../..");
const projectRoot = __dirname;
const pnpmHoistRoot = path.resolve(workspaceRoot, "node_modules/.pnpm/node_modules");

const config = getDefaultConfig(projectRoot);

config.watchFolders = [workspaceRoot];

config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, "node_modules"),
  path.resolve(workspaceRoot, "node_modules"),
  pnpmHoistRoot,
];

// When Metro (running from workspace root) tries to resolve
// ./node_modules/<pkg> and fails because pnpm doesn't create flat symlinks,
// redirect to the pnpm private hoist directory where packages actually live.
const _resolveRequest = config.resolver.resolveRequest;
config.resolver.resolveRequest = (context, moduleName, platform) => {
  // Intercept relative node_modules paths that fail at workspace root
  const relMatch = moduleName.match(/^(\.\.?\/)*node_modules\/(.+)$/);
  if (relMatch) {
    const pkgSubpath = relMatch[2]; // e.g. "expo-router/entry"
    const pnpmPath = path.resolve(pnpmHoistRoot, pkgSubpath);
    if (fs.existsSync(pnpmPath) || fs.existsSync(pnpmPath + ".js")) {
      return { filePath: fs.existsSync(pnpmPath) ? pnpmPath : pnpmPath + ".js", type: "sourceFile" };
    }
  }
  if (_resolveRequest) {
    return _resolveRequest(context, moduleName, platform);
  }
  return context.resolveRequest(context, moduleName, platform);
};

module.exports = config;
