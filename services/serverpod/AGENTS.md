# Serverpod project

This project is the Serverpod backend of **Nexo Social**, a network for creators
and communities. The Flutter app lives in `apps/nexo_social` (outside this
workspace) and consumes `nexo_client` by path. Serverpod + PostgreSQL are the
source of truth; Agora is only used for real-time media.

## Architecture

- `lib/src/shared/`: cross-cutting code — `auth/` (`session.requireUserId`,
  `NexoScopes`), `errors/` (`NexoException` + `NexoErrorCode`, the only error
  type sent to clients), `pagination/` (keyset `PageCursor`), `audit/`
  (`AuditLog` + `AuditService`), `gateways/` (interfaces for external providers,
  each with a real and a Fake implementation), `health/`.
- `lib/src/modules/<module>/{models,services,endpoints}`: identity, content,
  social, live, moderation, billing (P1 mock), notifications (P1), ai (P2).
- Endpoints stay thin (login, input validation, delegate). Business rules and
  transactions live in services. No repository layer: use the generated ORM.
- Global roles `moderator`/`admin` are Serverpod scopes; `creator` is a profile
  field. Guests are unauthenticated callers of public read endpoints.
- Live tokens are only issued by the server after validating the participant's
  role; clients never choose to become broadcasters.

## Serverpod workflow

Build for multiple users, use Serverpod's built-in authentication, which is already set up in `lib/server.dart`.

The user starts the server with `serverpod start`. There is no need to check if the server is running: make the changes and call the `serverpod` MCP tools as needed. If the server is not running, an informative error message will be received from the MCP server. Then STOP and ask the user to start it. NEVER start the server yourself.

While running, `serverpod start` watches for file changes to run incremental code generation and hot reload the running server.

Calling `serverpod generate` directly is not needed, but might be useful to troubleshoot when an incremental generation fails.

ALWAYS use the MCP server instead of the command line. Use the MCP server to:

- `create_migration` and `apply_migrations` for database (after you change data models).
- `create_repair_migration` if the database has drifted out of sync with the migrations.
- `tail_server_logs` to read logs from the server.
- `hot_reload` / `hot_restart` to reload or restart the server. Use `hot_restart` for changes that hot reload cannot apply, such as changes to `main()`.

NEVER edit generated code. The server's `lib/src/generated/` directory and the whole `nexo_client` package are rewritten by the code generator. Change the `.spy.yaml` models, the endpoints, or `lib/server.dart` instead.

Migrations are a narrow exception: the `migration.sql` of a generated migration MAY be edited by hand when the generated SQL would lose data — to add a data transformation, or to reach a destructive change through non-destructive steps. Never touch the other files in the migration directory, and keep the schema the SQL ends up with identical to `definition.sql` — new databases are created from that file and never run `migration.sql`.

Only when the server cannot be started at all, fall back to the CLI in the server package:

- `serverpod generate` to regenerate the client and the generated server code.
- `serverpod create-migration` after changing a model with a `table` (add `--force` for destructive changes). It only writes the migration; `serverpod start` applies pending migrations when it boots the server.

Tests need no Docker. `config/test.yaml` sets `database.dataPath`, so Serverpod starts and manages the test database (an embedded PostgreSQL) itself, and the project's `docker-compose.yaml` is not used for it. Just run `dart test` in the server package.

Checklist after doing changes, in this order:

- `dart analyze` (CLI)
- `dart format` (CLI)
- `create_migration` and `apply_migrations` (MCP - only if necessary)
- Do `serverpod` MCP `hot_restart` if required (hot reload is done automatically)
- Run tests, if applicable (`dart test` in the server package)
- Check `serverpod` MCP `tail_server_logs` for any issues.
