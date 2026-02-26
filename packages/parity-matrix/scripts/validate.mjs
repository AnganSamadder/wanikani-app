import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const routesPath = resolve(process.cwd(), "routes.json");
const required = [
  "route",
  "dataSource",
  "status",
  "tests",
  "knownGaps"
];
const statusValues = new Set(["planned", "in-progress", "complete"]);
const testsValues = new Set(["pending", "partial", "complete", "unit+ui-smoke"]);

const rows = JSON.parse(readFileSync(routesPath, "utf8"));
if (!Array.isArray(rows) || rows.length === 0) {
  throw new Error("routes.json must contain at least one route row");
}

for (const [index, row] of rows.entries()) {
  for (const key of required) {
    if (!(key in row)) {
      throw new Error(`Row ${index} is missing required field: ${key}`);
    }
  }

  if (!statusValues.has(row.status)) {
    throw new Error(`Row ${index} has invalid status: ${row.status}`);
  }
  if (!testsValues.has(row.tests)) {
    throw new Error(`Row ${index} has invalid tests status: ${row.tests}`);
  }
}

console.log(`Parity matrix validated (${rows.length} routes).`);
