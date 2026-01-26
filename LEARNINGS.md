# LEARNINGS.md

Project discoveries and lessons learned during WaniKani iOS development.

## Entry Format

### [DATE] - [Topic]
**Context:** What were you working on?
**Discovery:** What did you learn?
**Impact:** How does this affect the project?
**Code Example:** (if applicable)

---

## Entries

(Add entries below as you discover important patterns, gotchas, or solutions)

### 2026-01-25 - Project Initialization
**Context:** Setting up the three-prototype architecture
**Discovery:** Using PROTOTYPE_MODE environment variable allows runtime switching between WebView, Native, and Hybrid modes without code changes
**Impact:** Enables A/B testing and rapid iteration on UX approaches
