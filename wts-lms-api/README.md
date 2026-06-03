# WTS LMS API

Elixir Mix project for the WTS Canvas replacement API.

This project is the active implementation area for migrating WTS away from the
hosted Canvas LMS runtime toward a purpose-built API. The API keeps Canvas at the
boundary through import fixtures, legacy ID mappings, and audit metadata while
modeling the replacement system around WTS domain concepts.

## What Is Here

- Ecto/Postgres repo configuration and schema migrations for the replacement LMS
  domain.
- Domain contexts for course content, assignments, submissions, files, gradebook,
  imports, SIS dry runs, identity, authorization, audit, and notifications.
- Phoenix-compatible web/controller surfaces used by contract tests while the
  final runtime dependencies are selected.
- Sanitized Canvas pilot-course fixtures for deterministic migration and diff
  verification.
- Mix tasks for import diff checks, SIS dry runs, and gradebook fixture
  verification.

## Setup

```bash
mix deps.get
mix test
```

Development database settings use `WTS_LMS_DB_USER`, `WTS_LMS_DB_PASSWORD`,
`WTS_LMS_DB_HOST`, `WTS_LMS_DB_PORT`, and `WTS_LMS_DB_NAME`, with local defaults
in `config/dev.exs`.

Test database settings use the matching `WTS_LMS_TEST_DB_*` variables, with
fallbacks in `config/test.exs`.

## Useful Tasks

```bash
mix wts.import.diff path/to/fixture
mix wts.sis.dry_run path/to/file.csv
mix wts.gradebook.verify path/to/fixture.json
```

## Migration Principles

- Prefer a clean WTS LMS domain model over Canvas table-by-table cloning.
- Preserve Canvas source identity through explicit legacy mappings and audit
  fields.
- Validate behavior with sanitized Canvas evidence before expanding runtime
  dependencies.
- Keep API response contracts covered by tests so future Phoenix controllers can
  reject accidental shape drift.
