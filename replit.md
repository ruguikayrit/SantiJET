# ŞantiJET Monorepo

Turkish construction site management product. Multi-artifact pnpm workspace.

## Artifacts
- `artifacts/santiye-takip` (mobile, Expo) — Original mobile app, base `/`.
- `artifacts/santijet-neon` (web, Vite) — Neon HUD dashboard for site managers, base `/neon/`. Frontend-only, Zustand store with mock data (47 puantaj, 184 malzeme, 9 sevkiyat, 23 satın alma, 56 imalat, 312 kantar). Six module pages + home. Theme: dark #04060d + per-module neon color, JetBrains Mono numerals.
- `artifacts/api-server` (api) — Express API at `/api`.
- `artifacts/mockup-sandbox` (design) — Component preview sandbox at `/__mockup`. Hosts ŞantiJET tile mockups under `src/components/mockups/santijet-tiles/`.

## Conventions
- All UI text in Turkish. No emojis.
- Web app references the Neon HUD aesthetic from `artifacts/mockup-sandbox/src/components/mockups/santijet-tiles/Neon.tsx`.
- Use catalog dependencies and `@workspace/*` package names per pnpm-workspace skill.
