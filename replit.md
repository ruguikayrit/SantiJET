# Workspace

## Overview

pnpm workspace monorepo using TypeScript. Each package manages its own dependencies.

The active product in this workspace is **Şantiye Takip** — a Turkish-language construction site management mobile app for civil engineers managing multiple sites.

## Stack

- **Monorepo tool**: pnpm workspaces
- **Node.js version**: 24
- **Package manager**: pnpm
- **TypeScript version**: 5.9

## Artifacts

- `artifacts/santiye-takip` (Expo mobile app) — main product
- `artifacts/api-server` (Express + PostgreSQL) — multi-tenant workspace sync
  (push/pull JSON state by invite code) and `/api/workspaces/:code/ask` AI
  endpoint backed by Replit AI Integrations (OpenAI gpt-5-mini).
- `artifacts/mockup-sandbox` (component preview, unused — kept from template)

## Şantiye Takip — Architecture

- **Framework**: Expo + expo-router (Stack navigation)
- **Storage**: AsyncStorage (no backend, all data local on device)
- **State**: React Context (`context/AppContext.tsx`) — single source of truth
- **Fonts**: Inter (Google Fonts)
- **Icons**: Feather (`@expo/vector-icons`)
- **Theme**: Orange `#e85d04` + dark navy `#16213e`, light background `#f5f5f5`, radius 10
- **Storage key**: `santiye_app_data_v2` with one-time migration from legacy `santiye_app_data`

### Pages (`app/` — flat routing, all in Turkish)

- `index.tsx` — home with 9-tile grid of sections
- `proje.tsx` — Projeler (CRUD)
- `kesif.tsx` — Keşif (site survey + line items)
- `is-programi.tsx` — İş programı (work schedule with progress)
- `puantaj.tsx` — Puantaj (worker management + per-day attendance)
- `gunluk-rapor.tsx` — Günlük rapor (daily site report)
- `imalat.tsx` — İmalat (production tracking, planned vs completed)
- `gorev.tsx` — Görev (tasks with priority/status)
- `malzeme.tsx` — Malzeme (materials & stock)
- `butce.tsx` — Bütçe (income/expense ledger)

### Shared components (`components/`)

- `Header`, `BottomSheet`, `FormInput`, `PrimaryButton`, `EmptyState`
- `ProjectPicker` — horizontal chips for filtering by project
- `ErrorBoundary`, `ErrorFallback`
- `SmartSearch` — top-of-home search bar; instant fuzzy search across all entities
  (Turkish-aware normalization), respects role permissions; "Yapay Zekaya Sor"
  button calls `/api/workspaces/:code/ask` (cloud workspace required) for
  natural-language Q&A via OpenAI.

### Data entities (`context/AppContext.tsx`)

`Project`, `Survey` (+ `SurveyItem[]`), `ScheduleTask`, `Worker`, `Attendance`,
`DailyReport`, `Production`, `Task`, `Material`, `BudgetEntry`.

All entities are project-scoped via `projectId`. Deleting a project cascades and removes all related entities.

## Key Commands

- `pnpm --filter @workspace/santiye-takip run dev` — run mobile app (Expo dev server)
- `pnpm --filter @workspace/santiye-takip exec tsc --noEmit` — type-check mobile app
- `pnpm run typecheck` — full typecheck across all packages

See the `pnpm-workspace` skill for workspace structure and the `expo` skill for mobile app patterns.
