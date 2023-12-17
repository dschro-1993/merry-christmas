import {buildSync} from "esbuild"

buildSync({
  entryPoints: ["src/main.ts"],
  outfile:  "out/main.js",
  platform: "node",
  bundle:   true,
});
