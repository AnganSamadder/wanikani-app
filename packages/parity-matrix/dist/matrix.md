# WaniKani Route Parity Matrix

This markdown file mirrors `routes.json` for human review. `routes.json` is the machine-readable source used by tooling.

| Route | Data Source | Status | Tests | Known Gaps |
|---|---|---|---|---|
| dashboard | WaniKani API v2 | complete | unit+ui-smoke | Route-specific UI journey assertions are still pending (current coverage is ViewModel + launch smoke) |
| reviews | WaniKani API v2 | complete | unit+ui-smoke | Full end-to-end UI session test coverage (multi-item retries/error banners) is still pending |
| lessons | WaniKani API v2 | complete | unit+ui-smoke | Route-specific UI flow assertions for study->quiz->complete transitions are still pending |
| subjects/* | WaniKani API v2 | in-progress | partial | List/detail content still static; API-backed filtering pending |
| search | WaniKani API v2 | in-progress | pending | Search service + debounced query execution pending |
| extra-study/* | WaniKani API v2 | in-progress | pending | Burn review and recently-missed repositories not connected |
| settings/* | WaniKani API v2 | in-progress | partial | App/account/token forms and persistence plumbing pending |
| community/* | Discourse API | in-progress | partial | UI still static; live session/auth and moderation edge cases pending |
