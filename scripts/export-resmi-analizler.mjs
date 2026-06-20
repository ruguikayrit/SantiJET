import fs from "fs";
import path from "path";
import { createRequire } from "module";

const require = createRequire(import.meta.url);
const ts = require("typescript");
const srcPath = path.resolve(
  "artifacts/santiye-takip/constants/resmiAnalizler.ts",
);
const outPath = path.resolve(
  "artifacts/santiye-takip/assets/data/resmi-poz-analizleri.json",
);

const source = fs.readFileSync(srcPath, "utf8");
const result = ts.transpileModule(source, {
  compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 },
});
const mod = { exports: {} };
// eslint-disable-next-line no-new-func
new Function("exports", "module", "require", result.outputText)(mod.exports, mod, require);
const data = mod.exports.RESMI_POZ_ANALIZLERI;
if (!Array.isArray(data)) {
  throw new Error("RESMI_POZ_ANALIZLERI export not found");
}
fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, JSON.stringify(data));
console.log(`Exported ${data.length} analyses (${fs.statSync(outPath).size} bytes)`);
