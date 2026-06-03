# WTS LMS API Migration

This repository is no longer being used as a stock Canvas LMS application. It is
the working migration space for replacing the WTS Canvas deployment with a
purpose-built Elixir API.

The original Canvas LMS codebase remains in place as a reference point for
existing behavior, data semantics, and migration comparisons. New replacement
work lives under [`wts-lms-api`](./wts-lms-api), which contains the Elixir Mix
project for the WTS LMS API.

## Current Direction

- Build a clean WTS LMS domain model instead of cloning Canvas operational table
  shapes.
- Keep Canvas-specific identifiers at the boundary through legacy mapping,
  import metadata, and audit fields.
- Use sanitized Canvas pilot-course fixtures to validate imports, API response
  contracts, gradebook behavior, SIS dry runs, file handling, and notifications.
- Grow the Elixir API incrementally with contract-style tests before wiring in
  the final web/runtime dependencies.

## Elixir API Project

The active API scaffold is in [`wts-lms-api`](./wts-lms-api).

Key areas:

- `lib/wts_lms` - domain contexts for course content, assignments, submissions,
  files, gradebook, imports, identity, authorization, audit, and notifications.
- `lib/wts_lms_web` - Phoenix-compatible controller and contract surfaces for
  the future HTTP API.
- `priv/repo/migrations` - Ecto/Postgres schema migrations for the replacement
  domain.
- `test/fixtures/canvas_sample` - sanitized Canvas evidence used for deterministic
  importer and diff verification.
- `lib/mix/tasks` - migration support tasks such as import diff verification,
  SIS dry-run validation, and gradebook fixture verification.

## Working With the API

From the Elixir project directory:

```bash
cd wts-lms-api
mix deps.get
mix test
```

Database configuration is read from `WTS_LMS_DB_*` environment variables in dev
and `WTS_LMS_TEST_DB_*` in test, with local defaults defined in
`wts-lms-api/config/dev.exs` and `wts-lms-api/config/test.exs`.

Useful Mix tasks:

```bash
mix wts.import.diff path/to/fixture
mix wts.sis.dry_run path/to/file.csv
mix wts.gradebook.verify path/to/fixture.json
```

## Canvas Reference

The upstream Canvas README content has been replaced here because this checkout
is now focused on the WTS migration. For Canvas installation and operational
documentation, use the Instructure project wiki:

- [Canvas LMS wiki](https://github.com/instructure/canvas-lms/wiki)
- [Quick Start](https://github.com/instructure/canvas-lms/wiki/Quick-Start)
- [Production Start](https://github.com/instructure/canvas-lms/wiki/Production-Start)
