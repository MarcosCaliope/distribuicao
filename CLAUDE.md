# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Rails 8.0.5 / Ruby 3.4.5 rewrite of "Distribuidor", a legacy VB6 system used by a Brazilian
cartório (notary/registry office) network to import remessas (batch files) of títulos de
protesto (debt instruments sent for protest), validate them, distribute them across cartórios
by a rotation/lottery scheme, and export return manifests. See `docs/ANALISE_MIGRACAO.md` for
the full analysis of the legacy system, the migration plan by stage, and the specific bugs in
the VB6 code that are intentionally *not* being replicated — read it before touching the
import/distribution/export logic, since business-rule decisions and their rationale are
recorded there rather than in code comments.

The domain is Portuguese and should stay that way: model/column/variable names, validation
messages, and comments describing business rules are in Portuguese. Don't translate them to
English.

## Commands

```bash
bin/setup              # install deps, prepare db
bin/rails server       # run the app
bin/rails console

bin/rails test                          # unit/integration tests
bin/rails test test/models/titulo_test.rb        # single file
bin/rails test test/models/titulo_test.rb:12     # single test at line 12
bin/rails test:system                   # system tests (Capybara + headless Chrome)

bin/rubocop             # lint (rubocop-rails-omakase house style, see .rubocop.yml)
bin/rubocop -a          # autocorrect
bin/brakeman            # static security analysis
bin/importmap audit     # audit JS dependencies

bin/rails db:migrate
bin/rails db:test:prepare   # sync test db schema before running tests
```

CI (`.github/workflows/ci.yml`) runs `bin/brakeman`, `bin/importmap audit`, `bin/rubocop`, and
`bin/rails db:test:prepare test test:system` against a plain `postgres` service container.

## Database architecture — read before writing any migration or ETL code

The app connects to a **shared Postgres database** (`central`) that also holds ~40 legacy VB6
tables (`cad_titulos`, `cad_protesto`, `tblremessas`, `tes_*`, `esc_*`, `cax_*`, `cfg_*`,
`ace_usuario`, `log_monitora`, etc.) in the `public` schema. All new Rails tables live in a
dedicated `distribuidor` Postgres schema, set via `schema_search_path: distribuidor` in
`config/database.yml`. Any code that needs to read the legacy tables (ETL, comparisons) must
qualify them explicitly as `public.<table>` — the search path will not find them otherwise.

Because Rails' default `db/schema.rb` dumper ignores `schema_search_path` and dumps the whole
database, this app uses `config.active_record.schema_format = :sql` +
`config.active_record.dump_schemas = "distribuidor"` (`config/application.rb`) so
`db/structure.sql` only contains the `distribuidor` schema. Don't switch this back to
`schema.rb` — it will pull in the entire legacy schema and break `db:schema:load`.

Portuguese words that don't pluralize correctly under English rules are declared in
`config/initializers/inflections.rb` (`devedor→devedores`, `custa→custas`,
`distribuidor→distribuidores`). Add new irregular Portuguese plurals there rather than
renaming a model to dodge the inflector.

`OficioDistribuidor` (legacy `cad_distribuidor`, only 2 rows — "ofício distribuidor" is a
distribution office, not a person) is deliberately not named `Distribuidor` to avoid colliding
with the app/project name.

## Remessa import pipeline (`app/services/remessa_importacao/`)

This is the one nontrivial subsystem implemented so far (Etapa 2 of the migration plan).
`Importador#importar` reads a fixed-width remessa file (~600 bytes/line, ISO-8859-1 encoded)
and enforces, in order:

1. Whole-file checks first (`validar_ja_importado!`, `validar_caracteres!`,
   `validar_sequencia!`) — nothing is written to the DB until every structural check passes.
2. `Header`/`Detalhe`/`Trailer` (in `header.rb`/`detalhe.rb`/`trailer.rb`) parse fields by
   **1-based byte offset** (`Registro#campo`, mirroring VB6 `Mid()`), not by delimiter.
3. Per-título business validations (`avaliar_criticas`) replicate `frmImpTitulos.frm#Criticas`
   from the legacy app field-for-field, including its numeric irregularity codes. A key
   replicated quirk: **only the last failing check wins** — `codigo` is reassigned down a
   fixed sequence of `if` checks, not accumulated into a list. This is intentional parity with
   the legacy behavior, not a bug — do not "fix" it into an error list without checking
   `docs/ANALISE_MIGRACAO.md` first.
4. A título that fails validation is saved with `irregularidade` set, not rejected — matching
   legacy behavior of flagging rather than discarding.
5. `gravar!` wraps all writes (the `Remessa`, its `Titulo`s, `DevedorSolidario`s, and any
   auto-created `Devedor`s) in a single transaction, and attaches the original file to
   `Remessa` via Active Storage rather than the legacy approach of moving it to a
   `processados/` folder on disk.

Byte offsets in `Header`/`Detalhe`/`Trailer` were validated field-by-field against real
production files (`test/fixtures/files/remessas/`), not derived from the (partially inaccurate)
legacy source comments — see `docs/ANALISE_MIGRACAO.md` for the specific discrepancies found
(e.g. valor is at byte 247, not 261 as the legacy code comment claims). Treat the fixture files
as the ground truth if a byte offset looks suspicious.

## Model layer

Models under `app/models/` currently hold validations and associations only — no business
logic beyond `Remessa` and `Titulo` scopes. Business logic (distribution/rotation, export,
reports) is expected to land in services under `app/services/`, following the
`RemessaImportacao` pattern (a namespaced module per subsystem), not in models or controllers.

In `Titulo`, `protocolo_original` (immutable, legacy `seq_protocolo` value, only populated for
tracking data lineage during ETL) and `numero_protocolo_distribuido` (derived, computed once at
distribution time) are deliberately separate columns — the legacy system mutates a single
field in place for both purposes. Keep them separate in any new code.

No controllers/views/routes exist yet beyond the Rails health check — the app is still
backend/service-layer only (import pipeline + models). Distribution, export, and reporting
(Etapas 3–5 of the migration plan) are not implemented.

## Tests

Seed reference data (e.g. the 70 `Irregularidade` codes, extracted from the legacy
`FrmCadTitulos.frm#labelIrreg`) comes from `db/seeds.rb`, loaded once per test process via
`Rails.application.load_seed` in `test/test_helper.rb` — it is not fixture data, so don't
duplicate it into `test/fixtures/*.yml`.
