# Roadmap DPline

Ориентиры по времени — **не дедлайны под давление**, а рамка для приоритизации. Ритм: **вертикальные срезы** (UI → API → БД → деплой), после каждого — ревью и короткая запись в `plan/sessions/`.

---

## Фаза 0 — Каркас репозитория ✅

**Цель:** монорепа, health API, пустой web, CI lint/typecheck, Postgres Docker.

- pnpm workspaces (**без Turborepo** — [ADR-001](./decisions/001-monorepo-tooling.md)).
- `apps/web` (Vite 6 + React 19), `apps/api` (Node http + tsx), Postgres 16 в Docker.
- CI: lint + typecheck (смысловой паритет пакетов дожимается в Фазе 1).

**Готово:** каркас в `main` (через `dev`). Родитель: [#33](https://github.com/skv0r/dpline-task-manager/issues/33) описывает инвентарь.

---

## Фаза 1 — Prototype Cycle (ядро таск-менеджера) ← сейчас

**Цель:** localhost pre-MVP — прощупать web ↔ api ↔ db; **без дизайна и без auth**.  
Родитель: [#33](https://github.com/skv0r/dpline-task-manager/issues/33). Горизонт мягкий ~сер. сентября 2026.

- ADR: **Fastify** ([ADR-002](./decisions/002-api-http-framework.md)) + **Prisma** ([ADR-003](./decisions/003-orm-prisma.md)); web — feature-modules ([#36](https://github.com/skv0r/dpline-task-manager/issues/36)), не полный FSD.
- CI hygiene: lint+typecheck по делу (api+web), затем **test job** (Postgres + migrate — [#42](https://github.com/skv0r/dpline-task-manager/issues/42)).
- Модель Task + миграции + CRUD API + логи; hard delete, undo ~5 с на web.
- Web wireframe: список, create, edit, delete, фильтр по статусу.
- Тесты ядра + зелёный CI на PR в `dev`.

**Не в Фазе 1:** Today/NL/проекты/recurring/календарь/Pomo/habits, auth, Telegram, деплой как DoD, полный FSD, микрофронты.

**Готово, когда:** полный цикл задачи в UI без SQL; lint+typecheck+test в CI; ADR accepted; roadmap/backlog зеркалят фазы.

---

## Фаза 2 — Front shell

- Основной фронт-каркас (роутинг, layout) + подключение ядра Фазы 1.
- UI-структура **без** «дизайна/бренда» как цели; опционально FSD-lite.
- Продуктовые фичи конкурентов по приоритету: Today, быстрый capture, проекты…

---

## Фаза 3 — MVP

- Привычка пользоваться; прод/стейдж-контур; auth по ADR; деплой free-tier.

---

## Фаза 4 — MLP

- Polish / love; часть kill-фич (календарь/habits/focus — по решению).

---

## Дальше (бывший длинный roadmap — IceBox до стабильного ядра)

Расписание вуза, предметы/баллы, микродела, режим учёбы+музыка, конспекты+поиск, pgvector/ИИ, офлайн-sync, Telegram Mini App — **после** Фаз 1–3 по отдельным эпикам. Не смешивать с Prototype.

---

## Параллельно всегда

- ADR под нетривиальные решения.
- Тесты: **Vitest** + integration api; CI гоняет их (Фаза 1 DoD).
- Bugbot: `.cursor/BUGBOT.md` — границы модулей, CI, антипаттерны React, scope Фазы 1.
- Event-driven (очередь, outbox) — учебный спринт **после** скучного CRUD.
