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
| [#1](https://github.com/skv0r/dpline-task-manager/issues/1) | app-1-docs | open | ? | ? | `` | documentation |
| [#12](https://github.com/skv0r/dpline-task-manager/issues/12) | Пустой web с одной страницей | open | app | 0 | `app-12-web` | enhancement |
| [#14](https://github.com/skv0r/dpline-task-manager/issues/14) | CI: lint + typecheck | open | ? | ? | `` | enhancement |
| [#17](https://github.com/skv0r/dpline-task-manager/issues/17) | PostgreSQL локально + env | open | ? | ? | `` | enhancement |
<!-- backlog:auto:end -->

## После Фазы 0

- [ ] `todo` ADR: NestJS vs Fastify (или другой вариант).
- [ ] `todo` ADR: Prisma vs Drizzle.
- [ ] `todo` ADR: стратегия auth (один пользователь).
- [ ] `todo` Первая миграция + CRUD задачи.

## Идеи «не сейчас» (IceBox / вне доски)

- Telegram Mini App.
- Офлайн + sync.
- ИИ поверх конспектов.
- Импорт задач из GitHub.
- Недельная статистика + Chart.js в DPline (позже).
