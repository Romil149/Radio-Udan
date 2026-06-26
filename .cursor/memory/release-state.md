# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| Local WP plugin | 354 copy keys on `/config` | yes | 2026-06-25 | `https://radio` — `verify-wp-plugin.sh` PASS |
| GitHub `main` | `e8d91ae` (copy catalog, icons, migration) | yes | 2026-06-25 | Pushed |
| Staging WP plugin | old (17 copy keys on `/config`) | partial | 2026-06-25 | **BUG-018**: missing `require_once` for copy catalog caused wp-admin fatal when new files deployed |
| TestFlight iOS | 2.0.0+16 building | CI | 2026-06-25 | Triggered by push `74e2613` |
| Staging API smoke | 14/14 | — | 2026-06-25 | Public site + REST OK; wp-admin was broken |

## Open deploy blockers

1. Fix `class-app-copy-catalog.php` require in `radioudaan-app-api.php` (local fix applied).
2. Re-deploy **full** plugin folder to staging.
3. Commit + push Flutter icons/copy + bump build +16.
