import { build } from "esbuild";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const esbuildPluginPino = require("esbuild-plugin-pino");

await build({
  entryPoints: { index: "src/index.ts" },
  bundle: true,
  platform: "node",
  format: "esm",
  outdir: "dist",
  outExtension: { ".js": ".mjs" },
  sourcemap: true,
  plugins: [esbuildPluginPino()],
  external: [
    "cors",
    "cookie-parser",
    "drizzle-orm",
    "express",
    "firebase-admin",
    "firebase-admin/*",
    "pg",
    "pino",
    "pino-http",
    "pino-pretty",
  ],
});
