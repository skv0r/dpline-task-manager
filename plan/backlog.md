# Бэклог

Зеркало GitHub Project / Issues для ИИ. **Статус правды — на доске**, здесь краткий индекс.

Project: [DPLine Flow](https://github.com/users/skv0r/projects/1)  
Обновляет ассистент после чтения Project.

Статусы зеркала: `IceBox` | `Ready` | `In Progress` | `Review` | `Done` (как колонки Project).

## Родитель сессии процесса

| Issue | Название | Status | Type | Phase |
|-------|----------|--------|------|-------|
| [#1](https://github.com/skv0r/dpline-task-manager/issues/1) | app-1-docs (диспетчерская + правила в plan/) | IceBox | App | 0 |

## Фаза 0 (исполняемые)

| Issue | Название | Status | Type | Phase | Estimate |
|-------|----------|--------|------|-------|----------|
| [#10](https://github.com/skv0r/dpline-task-manager/issues/10) | Инициализировать монорепу | Ready | App | 0 | 2–3 h |
| [#11](https://github.com/skv0r/dpline-task-manager/issues/11) | Пустой api с `/health` | Ready | App | 0 | 1–2 h |
| [#12](https://github.com/skv0r/dpline-task-manager/issues/12) | Пустой web с одной страницей | Ready | App | 0 | 1–2 h |
| [#15](https://github.com/skv0r/dpline-task-manager/issues/15) | ADR: пакетный менеджер / тулчейн монорепы | Ready | App | 0 | 1 h |
| [#16](https://github.com/skv0r/dpline-task-manager/issues/16) | Практика: git flow (ветка → PR → merge в `dev`) | Done (закрыть руками если ещё open) | Prac | 0 | 0.5–1 h |
| [#14](https://github.com/skv0r/dpline-task-manager/issues/14) | CI: lint + typecheck | IceBox | App | 0 | 2 h |
| [#17](https://github.com/skv0r/dpline-task-manager/issues/17) | PostgreSQL локально + env | IceBox | App | 0 | 2 h |

Закрытые дубли (не брать в работу): `#2`–`#9`, `#13`.

## Авто-зеркало open issues

Обновляется `scripts/gh/sync-backlog.py` (из `/gh-create-task` и `/gh-start-task`).

<!-- backlog:auto:start -->
| Issue | Название | State | Type | Phase | Branch | Labels |
|-------|----------|-------|------|-------|--------|--------|
| [#33](https://github.com/skv0r/dpline-task-manager/issues/33) | Prototype Cycle: рабочий прототип таск-менеджера (Фаза 1) | open | app | 1 | `app-33-prototype` | enhancement |
| [#34](https://github.com/skv0r/dpline-task-manager/issues/34) | ADR: api framework + ORM (Nest/Fastify/thin × Prisma/Drizzle) | open | app | 1 | `app-34-adr-api-orm` | enhancement |
| [#35](https://github.com/skv0r/dpline-task-manager/issues/35) | CI hygiene: lint + typecheck по смыслу (api + web) | open | app | 1 | `app-35-ci-hygiene` | enhancement |
| [#36](https://github.com/skv0r/dpline-task-manager/issues/36) | ADR-004: web feature-modules (не полный FSD) | open | app | 1 | `app-36-adr-web-structure` | enhancement |
| [#37](https://github.com/skv0r/dpline-task-manager/issues/37) | Task schema + migrations | open | app | 1 | `app-37-task-schema` | enhancement |
| [#38](https://github.com/skv0r/dpline-task-manager/issues/38) | CRUD API tasks + logs + status filter | open | app | 1 | `app-38-tasks-api` | enhancement |
| [#39](https://github.com/skv0r/dpline-task-manager/issues/39) | Web: list + create + status filter | open | app | 1 | `app-39-web-list-create` | enhancement |
| [#40](https://github.com/skv0r/dpline-task-manager/issues/40) | Web: edit + delete/archive | open | app | 1 | `app-40-web-edit-delete` | enhancement |
| [#41](https://github.com/skv0r/dpline-task-manager/issues/41) | Core tests: CRUD + filters + volume | open | app | 1 | `app-41-core-tests` | enhancement |
| [#42](https://github.com/skv0r/dpline-task-manager/issues/42) | CI: test job (Postgres + migrate + pnpm test) | open | app | 1 | `app-42-ci-test` | enhancement |
| [#43](https://github.com/skv0r/dpline-task-manager/issues/43) | Phase 1 closeout: sessions + DoD sync | open | app | 1 | `app-43-phase1-docs` | enhancement |
<!-- backlog:auto:end -->

## Фаза 1 — Prototype Cycle

Родитель: [#33](https://github.com/skv0r/dpline-task-manager/issues/33) · вариант B (**B1∪B2** = один ADR api+ORM).

| # | Issue | Status | Branch | Фокус |
|---|-------|--------|--------|--------|
| B1 | [#34](https://github.com/skv0r/dpline-task-manager/issues/34) ADR api framework + ORM | In Progress | `app-34-adr-api-orm` | Fastify + Prisma ([ADR-002](./decisions/002-api-http-framework.md), [ADR-003](./decisions/003-orm-prisma.md)) |
| B2 | [#35](https://github.com/skv0r/dpline-task-manager/issues/35) CI hygiene | Ready | `app-35-ci-hygiene` | lint+typecheck по смыслу |
| B3 | [#36](https://github.com/skv0r/dpline-task-manager/issues/36) ADR-004 web structure | IceBox | `app-36-adr-web-structure` | feature-modules |
| B4 | [#37](https://github.com/skv0r/dpline-task-manager/issues/37) Task schema + migrations | IceBox | `app-37-task-schema` | Postgres |
| B5 | [#38](https://github.com/skv0r/dpline-task-manager/issues/38) CRUD API + logs | IceBox | `app-38-tasks-api` | curl e2e |
| B6 | [#39](https://github.com/skv0r/dpline-task-manager/issues/39) Web list+create+filter | IceBox | `app-39-web-list-create` | features/tasks |
| B7 | [#40](https://github.com/skv0r/dpline-task-manager/issues/40) Web edit+delete | IceBox | `app-40-web-edit-delete` | полный CRUD UI |
| B8 | [#41](https://github.com/skv0r/dpline-task-manager/issues/41) Core tests | IceBox | `app-41-core-tests` | Vitest / integration |
| B9 | [#42](https://github.com/skv0r/dpline-task-manager/issues/42) CI test job | IceBox | `app-42-ci-test` | Postgres → test |
| B10 | [#43](https://github.com/skv0r/dpline-task-manager/issues/43) Phase 1 closeout | IceBox | `app-43-phase1-docs` | sessions + DoD |

Опционально (не DoD): текстовое описание задачи, `packages/*` типы, DnD списка.

Auth ADR — **Фаза 3**, не здесь.

## Идеи «не сейчас» (IceBox / вне доски)

- Today / NL Quick Add / проекты / recurring / календарь / Pomo / habits (Фаза 2+).
- Полный FSD, Atomic Design-система, микрофронты.
- Telegram Mini App; офлайн + sync; ИИ поверх конспектов.
- Импорт задач из GitHub; недельная статистика + Chart.js.
