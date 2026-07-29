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

`Importador`'s own class-level comment lists the specific points where it intentionally departs
from legacy behavior (irregular título with unregistered `tipo_titulo` gets a null FK instead of
the legacy `'*'` sentinel, `protocolo_original` is left blank for new títulos, `cpf_cnpj` keeps
leading zeros instead of round-tripping through a `Double` like the VB6 code does) — check it
alongside `docs/ANALISE_MIGRACAO.md` before "fixing" something that looks like a discrepancy.

The praça/cidade crítica (irregularidade 15) compares against a "cidade sede" that was
hardcoded to `"FORTALEZA"` in the legacy VB6 (`frmImpTitulos.frm`); here it's
`config.x.remessa.cidade_sede`, overridable via the `REMESSA_CIDADE_SEDE` env var, so the app
isn't locked to one client's comarca.

## Distribuição de títulos (`app/services/distribuicao/`)

Etapa 3. `Processador#processar` (replicating `frmDistribuicaoNew.cmdProcessar_Click`) is the
entry point: `CriadorDia` first guarantees a `VagaDistribuicao` (cartório x faixa de custas) row
exists for the day, inheriting `livre` from the most recent prior row for that same pair (or
`false` if there's never been one); then each `Titulo.pendentes_distribuicao` is distributed in
its **own** transaction — a título with no matching `FaixaCusta` is collected as a `Falha`
struct rather than aborting the batch, the same "flag, don't abort" precedent as
`RemessaImportacao`. `SorteioCartorio` and `RodizioOficio` are two independent draws: the former
locks the faixa's vagas `FOR UPDATE` and samples a free one (resetting the whole faixa to
`livre` when none remain) — this `FOR UPDATE` is a deliberate fix of the legacy's unlocked
`UPDATE ... WHERE blivre=true` race, see `docs/ANALISE_MIGRACAO.md`; the latter just alternates
between the 2 registered `OficioDistribuidor`s, unrelated to the cartório sorteio. `Desfazedor`
(undo) only clears the título's own distribution/export FKs — it does **not** return the vaga or
ofício to `livre`, matching legacy behavior where undoing affects only the título, not the day's
rodízio.

## Exportação de manifestos e retornos (`app/services/exportacao/`)

Etapa 4. Two writers share `FormatoFixo` (padding helpers mirroring legacy `TrataString`/
`TrataMoeda`/`TrataDuplo`): `GeradorManifesto` writes the internal per-ofício-distribuidor
manifest (pure detail lines, no header/trailer — confirmed the legacy form declares those
variables but never uses them) and deliberately widens two fixed-width fields versus the legacy
layout (tipo de documento 4 bytes not 3, tipo de título 3 not 2) since it's a new,
Rails-only-consumed format and truncating back to the old width would cut real data.
`GeradorRetorno` writes the per-cartório+apresentante bank-return file by **reconstructing** the
fixed-width line from `Titulo` columns (Rails doesn't keep the legacy's raw per-título line) —
its byte offsets are kept in manual sync with `remessa_importacao/{header,detalhe,trailer}.rb`
and must be re-checked there on any import-side offset change. Both attach the generated file to
`ManifestoDistribuidor`/`RetornoExportado` via Active Storage and stamp that FK back onto every
included `Titulo` (which is what `Desfazedor`, above, has to clear). `GeradorRetorno` also
enqueues `Exportacao::EnvioRetornoJob` to email the file — new behavior with no legacy
equivalent (legacy sending was a manual Outlook/COM automation triggered by a button).

## Relatórios (`app/services/relatorios/`, `app/controllers/relatorios/`)

Etapa 5. Every report is a plain service (one per legacy `frmRel*`/`frmCadApresentantes` form)
returning a `Relatorios::Dataset` (title/subtitle/columns/rows struct) — the single shape both
the shared HTML view (`app/views/relatorios/tabela.html.erb`) and `Relatorios::TabelaPdf`
(Prawn) render, replacing what was a copy-pasted staging-table-and-print-button per legacy
screen. `Relatorios::ApplicationController` is the one place the html/pdf dual response format
(`renderizar`) and the authorization gate live, so the individual report controllers under
`app/controllers/relatorios/` stay thin action methods. A few reports are intentionally narrower
than their legacy counterpart where the missing scope depends on a feature this app doesn't have
yet (e.g. `TitulosEventuais` filters on manually-registered títulos, which can't exist until a
manual-entry feature is built) — see each service's own comment and
`docs/ANALISE_MIGRACAO.md`'s Etapa 5 section before treating an empty result as a bug.

## Autenticação e autorização (Etapa 6)

Session-based (`Usuario`/`Sessao`, `has_secure_password`, signed cookie) — the `Autenticacao`
controller concern (`app/controllers/concerns/autenticacao.rb`) enforces login on every
controller that includes it, plus a mandatory password change (`deve_trocar_senha`) for
legacy-imported users, checked *after* authentication so it can redirect an already-logged-in
user instead of blocking the login page itself. Authorization is real Pundit policies under
`app/policies/` (e.g. `RelatorioPolicy#ver?`, gating all of Relatórios above) backed by a plain
`Perfil`/`Permissao`/`PerfilPermissao`/`PerfilUsuario` RBAC join (`Usuario#tem_permissao?`) — not
ad-hoc `if` checks in controllers. `Autenticacao::ImportadorUsuariosLegado` imports
`public.cad_usuario` the same way the Etapa 7 ETL importers below do (raw SQL, idempotent, rake
task, kept out of `db/seeds.rb`/CI) but never carries over the legacy password (item 15 of
`docs/ANALISE_MIGRACAO.md` — treated as compromised): every imported user gets a fresh random
password and is forced to change it on first login.

## ETL de dados legados (`app/services/etl/`, `lib/tasks/etl.rake`)

Etapa 7 of the migration plan. Two independent things, not one "migrate everything" task — see
`docs/ANALISE_MIGRACAO.md` items 17-18 for why:

1. **Dimension/reference-data import** — `Etl::Importador{Cartorios,OficiosDistribuidores,
   Bancos,Apresentantes,TiposTitulo,FaixasCusta,Feriados}`, one per legacy `public.*` table,
   run via `bin/rails etl:importar_dimensoes` (or per-table, e.g. `bin/rails etl:bancos`).
   Idempotent (`find_or_create_by!`/skip-if-exists on a natural key, usually `codigo_legado`),
   catches per-row failures (e.g. `TipoTitulo` has real duplicate `abreviatura`s under
   different legacy codes) without aborting the batch. These are the only source of `Cartorio`/
   `Banco`/`Apresentante`/`TipoTitulo`/`FaixaCusta`/`Feriado`/`OficioDistribuidor` data — none of
   it is seeded any other way.
2. **Historical replay validation** — `Etl::ReconstrutorRemessa` reassembles a historical
   remessa file byte-for-byte from `public.tblremessas.sregistro` (each detail line already
   carries its own position at bytes 597-600, no external ordering column needed);
   `Etl::ValidadorReplayHistorico` runs the reconstructed file through the **real, unmodified**
   `RemessaImportacao::Importador` inside a transaction that always rolls back, and diffs the
   computed `irregularidade` against the legacy-recorded `icodirreg` for the same line. Run via
   `bin/rails "etl:validar_replay_historico[data_inicio,data_fim]"`. **This never persists a
   título** — `public.cad_titulos`/`cad_devedor` are empty in the legacy DB (títulos get purged
   once resolved), so there is no live "pending" legacy data to backfill; this is a confidence
   check on the ported business rules, not a migration.

Same structural precedent as `Autenticacao::ImportadorUsuariosLegado` (Etapa 6): raw SQL against
`public.<table>` (the `distribuidor` schema's `search_path` won't find them otherwise), kept
**out of `db/seeds.rb` and out of CI** — `.github/workflows/ci.yml` runs against a blank
`postgres` service container with no legacy `public` schema data at all, so anything reading
`public.*` would break CI if it ran automatically. Tests for anything touching a `public.*`
table create that table with raw SQL in `setup` and drop it in `teardown` (see
`test/services/etl/*_test.rb` or the Etapa 6 precedent) — never assume a legacy table exists in
the test DB by default.

**Be careful running ad-hoc scripts against `public.*` tables in the dev DB** — unlike the test
DB (where these tables are always fixtures your own `setup`/`teardown` creates and destroys),
the dev DB has the *real* restored legacy data. A throwaway verification script that
`CREATE TABLE IF NOT EXISTS`s or `DELETE FROM`s a `public.*` table is a no-op or a fixture
operation in test, but a real, unscoped mutation in dev — scope every statement narrowly (a
`WHERE` clause, not a bare table name) if you're touching `public.*` outside the test DB.

## Operações — corte/cutover entry points (Etapa 8, `app/controllers/operacoes/`)

Etapas 2–5 only exposed their services through tests — no controller, no rake task, nothing a
real operator could click. A strangler-fig cutover (see `docs/ANALISE_MIGRACAO.md`'s "Plano por
etapas", Fases 0–5) needs an operator-usable Rails screen before any VB6 screen can be retired,
so Etapa 8 added the missing entry points rather than new business logic:

- `Operacoes::RemessasController#create` uploads a file straight into
  `RemessaImportacao::Importador`; `DistribuicoesController#create`/`#destroy` call
  `Distribuicao::Processador`/`Desfazedor`; `ExportacoesController#create` calls both
  `Exportacao::Gerador{Manifesto,Retorno}`. All run synchronously (no background job — daily
  volume doesn't need one) and share one `OperacaoPolicy`/`operar_distribuicao` permission; don't
  split it into finer-grained permissions without a real reason, since nothing today
  distinguishes who's allowed to do which of these.
- `ValidacoesSombraController#index` lists `ValidacaoSombraExecucao` rows. `Etl::ValidacaoSombraJob`
  (scheduled daily in `config/recurring.yml` via Solid Queue) reruns the existing
  `Etl::ValidadorReplayHistorico` — unmodified — for the previous day and persists the result,
  because nobody would tail a rake task's stdout during a multi-week shadow-validation window.
  The `etl:validar_replay_historico` rake task itself is untouched and still the tool for one-off
  historical analysis over an arbitrary date range.
- `Relatorios::MenuController` (mounted at both `/` and `/relatorios`) is the first real
  navigable entry point for the 7 report modes from Etapa 5 — before this there was no root
  route and no link between them, only direct URLs (this exact gap was flagged in a comment in
  `Autenticacao#url_apos_autenticacao`, now resolved).

Two Rails pluralization gotchas hit while building this, both fixed the same way (an irregular
inflection, not a workaround): `resource :exportacao` and a model named `*Execucao` both
pluralize wrong under English rules (`exportacaos`, not `exportacoes`) — see the `"exportacao"`/
`"execucao"` entries in `config/initializers/inflections.rb`. Separately, `resources
:validacoes_sombra` (a resource name containing an underscore) makes Rails generate an
`..._index` path helper suffix instead of the expected bare name — sidestepped by using an
explicit `get ..., as: :validacoes_sombra` instead of `resources`, matching how `relatorios`
routes already do plain `get` for simple index-style pages.

## Model layer

Models under `app/models/` hold validations, associations, and scopes only (plus the odd
one-line query method, e.g. `Usuario#tem_permissao?`) — no business logic. Business logic
(import, distribution/rotation, export, reports, ETL) lives in services under `app/services/`,
one namespaced module per subsystem (`RemessaImportacao`, `Distribuicao`, `Exportacao`,
`Relatorios`, `Autenticacao`, `Etl`), not in models or controllers.

In `Titulo`, `protocolo_original` (immutable, legacy `seq_protocolo` value, only populated for
tracking data lineage during ETL) and `numero_protocolo_distribuido` (derived, computed once at
distribution time) are deliberately separate columns — the legacy system mutates a single
field in place for both purposes. Keep them separate in any new code.

Etapas 3–7 of the migration plan (distribution/rotation, export/manifests, reports, auth, and
legacy-data ETL) are all implemented — see the corresponding sections above and
`docs/ANALISE_MIGRACAO.md`'s "Plano por etapas" for what each covers. Etapa 8 (cutover)'s code
side is also done (see Operações section above) — what's left across all its phases is
operational/business decisions only the user can make (running the one-time legacy user import
against real data, how long to run shadow validation, which day to cut over
distribuição/exportação), not code, and is tracked in `docs/ANALISE_MIGRACAO.md` rather than here.

## Tests

Seed reference data (e.g. the 70 `Irregularidade` codes, extracted from the legacy
`FrmCadTitulos.frm#labelIrreg`) comes from `db/seeds.rb`, loaded once per test process via
`Rails.application.load_seed` in `test/test_helper.rb` — it is not fixture data, so don't
duplicate it into `test/fixtures/*.yml`.
