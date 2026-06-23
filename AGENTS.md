# AGENTS.md

## Cursor Cloud specific instructions

ŞantiJET is a Turkish construction-site management product in a pnpm workspace
monorepo (see `replit.md` for the artifact overview). Dependencies are installed
with `pnpm install` (the startup update script already runs this). Use `pnpm`
only — npm/yarn are blocked by the root `preinstall` hook. Node 22 works fine even
though `.replit` pins nodejs-24.

### Services and how to run them (dev mode)

All run commands are defined in each artifact's `package.json` `scripts`. Each Vite
artifact requires a `PORT` env var or it throws on startup.

| Service | Command | Notes |
|---|---|---|
| `artifacts/santijet-neon` (web HUD dashboard, flagship) | `PORT=23301 BASE_PATH=/ pnpm --filter @workspace/santijet-neon run dev` | Frontend-only, mock data. No DB. |
| `artifacts/santijet-website` (web) | `PORT=8082 pnpm --filter @workspace/santijet-website run dev` | Frontend-only. |
| `artifacts/mockup-sandbox` (design sandbox) | `PORT=8081 BASE_PATH=/__mockup pnpm --filter @workspace/mockup-sandbox run dev` | Frontend-only. |
| `artifacts/santiye-takip` (Expo mobile app) | `PORT=24915 pnpm --filter @workspace/santiye-takip run dev:web` | Expo/Metro. First web bundle takes ~15s. `dev` (vs `dev:web`) targets native via Expo Go and relies on `REPLIT_*` env vars. |
| `artifacts/api-server` (Express API) | see env requirements below | Requires Postgres. |

### api-server run caveats (non-obvious)

`artifacts/api-server` will throw on startup unless these env vars are set:

- `PORT` (e.g. `8080`)
- `SESSION_SECRET` — min 16 chars, used for HMAC session tokens
- `DATABASE_URL` — Postgres connection string. `@workspace/db` throws at import
  time if unset, so this is required even for non-DB routes.

Point `DATABASE_URL` at any reachable Postgres (`.replit` provides the
postgresql-16 module locally), then create the `workspaces` table with
`DATABASE_URL=... pnpm --filter @workspace/db run push` (drizzle-kit) before
starting the server. Run with:

```
PORT=8080 SESSION_SECRET=<16+ chars> DATABASE_URL=postgresql://USER:PASS@localhost:5432/DB \
  pnpm --filter @workspace/api-server run dev
```

`dev` rebuilds via esbuild (`build.mjs`) then runs `dist/index.mjs` — it is not a
watch/hot-reload server, so re-run it after code changes. Health check:
`GET /api/healthz` → `{"status":"ok"}`. The AI route (`/api/workspaces/:code/ask`)
returns 503 unless `AI_INTEGRATIONS_OPENAI_BASE_URL` and
`AI_INTEGRATIONS_OPENAI_API_KEY` are set; everything else works without them.

### Typecheck/build caveat

The root `pnpm run typecheck` (and therefore `pnpm run build`, which runs typecheck
first) currently fails with pre-existing TypeScript errors in `artifacts/api-server`
(`src/lib/auth.ts`, `src/routes/*.ts` — Express 5 `req.params` and Node crypto
typings). These are committed code issues unrelated to environment setup; the
api-server still builds and runs because its build uses esbuild, not tsc. Other
packages typecheck cleanly.

### Flutter (santijet-bfa-flutter, santijet-demir)

A Flutter SDK is baked into the base image at `$HOME/flutter` (Flutter 3.44.3
stable / Dart 3.12.2). `$HOME/flutter/bin` is added to `PATH` via `~/.bashrc`, so
interactive shells get `flutter` automatically; non-interactive contexts (and the
startup update script) must reference `$HOME/flutter/bin/flutter` explicitly.

Web (`flutter build web` / `-d chrome`) and Linux desktop (`flutter build linux`)
toolchains are precached and verified green via `flutter doctor`. Android shows ✗
(no Android SDK) — expected/out of scope. The Linux desktop apt deps are
`ninja-build libgtk-3-dev mesa-utils clang cmake pkg-config`. Note: clang 18
auto-selects the GCC 14 toolchain, so `libstdc++-14-dev` (plus `g++`) must be
present or C++ linking fails with `cannot find -lstdc++`; these are installed in
the base image.

Flutter projects:
- `artifacts/santijet-bfa-flutter` — ŞantiJET BFA (Birim Fiyat Analizleri). Run
  `flutter pub get` then `flutter run -d chrome` / `flutter build web` /
  `flutter build linux`. Generated `*.g.dart` / `*.freezed.dart` files are
  committed; if you change annotated models, regenerate with
  `dart run build_runner build`. This artifact is NOT part of the pnpm workspace.
- `artifacts/santijet-demir` — separate Flutter app (also outside the pnpm
  workspace); see its `README.md`.
