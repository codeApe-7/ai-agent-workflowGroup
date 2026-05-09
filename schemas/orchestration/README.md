# Orchestration JSON Schemas

JSON Schema (Draft-07) contracts for `.orchestration/<session>/` artifacts. These schemas are the single source of truth for the shape of every artifact written by `scripts/orchestration/session.cjs`.

## File map

| Schema | Artifact | Owner | When written |
|--------|----------|-------|--------------|
| [`session.schema.json`](session.schema.json) | `.orchestration/<session>/session.json` | main session | on `init`, on every worker change |
| [`plan.schema.json`](plan.schema.json) | `.orchestration/<session>/plan.json` | main session | on `plan` (refresh) — aggregated snapshot |
| [`task.schema.json`](task.schema.json) | `.orchestration/<session>/<worker>/task.json` | main session | on `add-worker` (skipped for `--lightweight`) |
| [`handoff.schema.json`](handoff.schema.json) | `.orchestration/<session>/<worker>/handoff.json` | main session | on `add-worker` (Pending), `append`, `complete` |
| [`status.schema.json`](status.schema.json) | `.orchestration/<session>/<worker>/status.json` | main session | on `add-worker`, `set-status` |

## Conventions

- **Slug pattern**: `^[a-z0-9][a-z0-9-]*$` for `session.name`, `worker`, `dependsOn[]` items.
- **Timestamps**: ISO-8601 (`new Date().toISOString()`), millisecond precision dropped to seconds (`.replace(/\.\d+Z$/, 'Z')`).
- **schemaVersion**: every artifact carries `"schemaVersion": "1.0"`. Bump when shape changes incompatibly; consumers must validate before reading new fields.
- **Append-only fields**: `handoff.notes[]` and `status.history[]` accumulate; never overwrite — only push.
- **Final-state fields**: `handoff.summary` / `filesChanged` / `validation` / `followUps` are mutable; `finalizedAt` flips them from "Pending" to "Final".

## Code-reviewer special

`code-reviewer` worker MUST populate `handoff.stages.spec` (规格符合性) and `handoff.stages.quality` (代码质量). The `orchestration-artifacts` hook check enforces this before allowing the session to close.

## Validation

```bash
# Validate a single session against schemas
node scripts/orchestration/session.cjs validate <session>

# Schemas are also consumable by external tools (LLMs, CI) — point them at this directory.
```

## Why JSON-only

Earlier versions used markdown (`task.md` / `handoff.md` / `status.md`) for human readability. We moved to JSON because:

1. **Machine-consumable**: hooks, CLI, and downstream agents can read fields by name instead of regex-parsing markdown.
2. **Schema-backed**: incompatible writes fail loudly via validation, instead of silently producing malformed reports.
3. **Stable contract**: schemas version independently from prose docs.

Human-readable views can be regenerated on demand from the JSON via `session.cjs render` (planned), but the JSON files are the ONLY truth source.
