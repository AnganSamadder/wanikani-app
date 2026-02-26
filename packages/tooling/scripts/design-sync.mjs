#!/usr/bin/env node
import { execSync } from "node:child_process";
import { existsSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(scriptDir, "../../..");

execSync("bun run --cwd packages/design-tokens build", { stdio: "inherit", cwd: repoRoot });
execSync("bun run --cwd packages/parity-matrix validate", { stdio: "inherit", cwd: repoRoot });
execSync("bun run --cwd apps/ios ios:generate", { stdio: "inherit", cwd: repoRoot });

const requiredArtifacts = [
  "apps/ios/designs/wanikani-master.pen",
  "apps/ios/designs/frame-manifest.json",
  "apps/ios/WaniKani/Shared/Theme/WKDesignTokens+Generated.swift",
  "apps/android/app/src/main/kotlin/com/angansamadder/wanikani/android/tokens/WkTokensGenerated.kt"
];

for (const artifact of requiredArtifacts) {
  const fullPath = resolve(repoRoot, artifact);
  if (!existsSync(fullPath)) {
    throw new Error(`Missing required design-sync artifact: ${artifact}`);
  }
}

console.log("Design sync complete.");
