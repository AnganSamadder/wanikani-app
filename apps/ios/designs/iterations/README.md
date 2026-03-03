# Design Iteration History

Use this folder as an append-only timeline for `.pen` design milestones.

Naming convention:
- `iter-###-short-label.pen`
- `###` is zero-padded and strictly increasing.

Required workflow:
1. Copy current `apps/ios/designs/wanikani-master.pen` into a new `iter-###-...pen` file.
2. Add an entry to `iteration-log.json` with summary + rationale.
3. Continue editing only `wanikani-master.pen`.

This keeps the master editable while preserving a recoverable visual history.

Current caveat:
- In this environment, some Pencil MCP edits remain in the live editor session and may not flush to disk automatically.
- When that happens, log the pass in `iteration-log.json` with `file: "live-mcp-session"` and keep screenshot evidence for the checkpoint.
