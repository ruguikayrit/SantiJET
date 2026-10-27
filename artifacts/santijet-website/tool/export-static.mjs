import { cpSync, readdirSync, rmSync, statSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const dist = path.resolve(here, "../dist/public");
const out = path.resolve(here, "../../santijet-web");
const keep = new Set(["wrangler.jsonc"]);

for (const name of readdirSync(out)) {
  if (keep.has(name)) continue;
  rmSync(path.join(out, name), { recursive: true, force: true });
}

for (const name of readdirSync(dist)) {
  const from = path.join(dist, name);
  const to = path.join(out, name);
  cpSync(from, to, { recursive: true });
}

const index = statSync(path.join(out, "index.html"));
if (!index.isFile()) {
  throw new Error("Static export is missing index.html");
}
