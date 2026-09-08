# Kijani School Fee Management

Role-aware school finance workspace for admins and accountants, with a Flutter mobile/desktop client and PostgreSQL-backed API.

## Run & Operate

- `pnpm --filter @workspace/api-server run dev` — run the API server (port 5000)
- `pnpm run typecheck` — full typecheck across all packages
- `pnpm run build` — typecheck + build all packages
- `pnpm --filter @workspace/api-spec run codegen` — regenerate API hooks and Zod schemas from the OpenAPI spec
- `pnpm --filter @workspace/db run push` — push DB schema changes (dev only)
- Required env: `DATABASE_URL` — Postgres connection string

## Stack

- pnpm workspaces, Node.js 24, TypeScript 5.9
- API: Express 5
- DB: PostgreSQL + Drizzle ORM
- Validation: Zod (`zod/v4`), `drizzle-zod`
- API codegen: Orval (from OpenAPI spec)
- Build: esbuild (CJS bundle)

## Where things live

- `flutter_app/` — Flutter/Dart client for mobile and desktop
- `artifacts/api-server/src/routes/school.ts` — school finance API and demo seed flow
- `lib/db/src/schema/school.ts` — PostgreSQL schema for students, classes, payments, activity, notifications, and campaigns
- `outputs/school-fee-management-flutter-source.zip` — packaged Flutter client plus backend source

## Architecture decisions

- Flutter owns the responsive client surface; the Node/Express service remains the shared remote API for mobile and desktop sync.
- PostgreSQL is the source of truth for operational records; the API seeds a small demo dataset only when the school tables are empty.
- Equity Bank is represented as an explicit sync boundary so live credentials and webhook rules can be added without changing the client contract.
- Parent communications are modeled as campaigns so WhatsApp, bulk email, and SMS providers can be attached independently.

## Product

- Admins can review dashboard totals, notifications, accountant activity, payments, and messaging status.
- Accountants can add students and classes, record manual payments, and queue parent communication campaigns.
- Payment receipts and balances are represented in the same data model as automated bank updates.

## User preferences

_Populate as you build — explicit user instructions worth remembering across sessions._

## Gotchas

_Populate as you build — sharp edges, "always run X before Y" rules._

## Pointers

- See the `pnpm-workspace` skill for workspace structure, TypeScript setup, and package details
