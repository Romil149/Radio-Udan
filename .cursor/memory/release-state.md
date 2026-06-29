# Release state
<!-- Update after every deploy, CI build, or verification pass. -->

| Layer | Version / commit | Deployed? | Last verified | Notes |
|-------|------------------|-----------|---------------|-------|
| Local WP plugin | 354 copy keys on `/config` | yes | 2026-06-25 | `https://radio` — `verify-wp-plugin.sh` PASS |
| GitHub `main` | `3fcf876` | yes | 2026-06-27 | A11y branch merged + white launcher icon |
| TestFlight iOS | 2.0.0+21 | CI triggered | 2026-06-27 | Push `3fcf876` → **Build iOS IPA** workflow |
| Staging API smoke | 14/14 | — | 2026-06-27 | PASS from cloud agent |

## Open deploy blockers

1. Fix `class-app-copy-catalog.php` require in `radioudaan-app-api.php` (local fix applied).
2. Re-deploy **full** plugin folder to staging.
3. Commit + push Flutter icons/copy + bump build +16.
