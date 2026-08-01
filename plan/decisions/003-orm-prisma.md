# 003. ORM: Prisma + hard delete; контракт типов в packages/*

Дата: 2026-08-01  
Статус: **accepted**  
Связанные issues: [#34](https://github.com/skv0r/dpline-task-manager/issues/34), schema [#37](https://github.com/skv0r/dpline-task-manager/issues/37), CI test [#42](https://github.com/skv0r/dpline-task-manager/issues/42); родитель [#33](https://github.com/skv0r/dpline-task-manager/issues/33)

## Контекст

Фаза 1: PostgreSQL уже локально (Docker, `DATABASE_URL` в корневом `.env` — см. #17). Нужен ORM и стратегия миграций/удаления данных для сущности Task.

Приоритеты (2026-07-27): рынок/учёба и скорость до CRUD выше глубокого изучения migrate-story; **CI ценится высоко** — migrate в пайплайне, когда появится test job.

HTTP-слой: Fastify — [ADR-002](./002-api-http-framework.md).

## Критерии выбора (упорядочены)

1. Документация и встречаемость (Prisma / Drizzle).  
2. Быстрый путь: schema → migrate → CRUD.  
3. Типобезопасность TS без ручного SQL на каждый запрос.  
4. Миграции в CI вместе с тестами (#42), без сложного migrate-ритуала в #34.  
5. Не тащить `@prisma/client` в `apps/web`.

## Варианты

### A. Prisma ← **выбрано**

Плюсы: сильный DX, migrate, Prisma Studio, много примеров; привычный выбор в стартапах.  
Минусы: клиент и schema — отдельный mental model; иногда «магия» vs SQL-first.

### B. Drizzle

Плюсы: ближе к SQL, лёгкий бандл.  
Минусы: меньше «батареек» из коробки для текущего фокуса обучения; можно revisit отдельным ADR.

### C. Сырой `pg` / SQL без ORM

Отклонено для ядра Prototype: медленнее до CRUD и больше boilerplate.

### D. Soft delete vs hard delete

См. решение: **hard delete** на api.

## Решение

**Prisma** как ORM для `apps/api`. Миграции — **Prisma Migrate**.

### Удаление задач

- **Api:** `DELETE` = **hard delete** (строка исчезает из БД).  
- **Web (UX):** «удалить» → уведомление с **отменой ~5 сек**; если не отменили — тогда вызвать `DELETE`.  
  Серверного «pending delete» / soft-delete в Prototype **нет**.  
  Детали UI — в [#40](https://github.com/skv0r/dpline-task-manager/issues/40); api не хранит отложенное удаление.

### Контракт типов (`packages/*`)

Сразу, когда появится schema Task (#37):

- пакет вроде `packages/shared` (или `packages/task-contract`): **Zod-схемы** + выведенные типы (`Task`, `CreateTaskInput`, …);  
- **web** и **api** импортируют контракт оттуда;  
- **`@prisma/client` только в api** — не экспортировать Prisma-модели в web.

### CI и миграции

- В #34 **не** разворачиваем полный migrate-процесс ради ADR.  
- В [#42](https://github.com/skv0r/dpline-task-manager/issues/42): service Postgres + **`prisma migrate deploy`** + `pnpm test`.  
- Локально: `migrate dev` / обычный Prisma workflow — в #37.

### Схема Task

Поля и статусы — в #37 (не дублировать продуктовую схему здесь). ORM-решение не зависит от финального списка колонок.

## Последствия

### Плюсы

- Быстрый CRUD и типы из schema.  
- Чёткая граница: Prisma внутри api, Zod-контракт наружу.  
- Hard delete проще soft-delete; undo на клиенте достаточен для одного пользователя.

### Минусы и долги

- Нужен shared-пакет и дисциплина «не импортировать Prisma в web».  
- Hard delete необратим после запроса — UX отмены обязан быть на web.  
- Переезд на Nest ([ADR-002](./002-api-http-framework.md)) сохраняет Prisma (или отдельное решение в ADR миграции).

### Follow-up

- [ ] #37 — `schema.prisma`, первая миграция Task, инициализация Prisma в api.  
- [ ] #37 — `packages/shared` (Zod + типы), api мапит Prisma → контракт.  
- [ ] #38 — CRUD через Prisma в `services` / `db`.  
- [ ] #40 — UI: hard delete + тост «отменить» ~5 с.  
- [ ] #42 — CI: Postgres + `prisma migrate deploy` + tests.

## Отклонённое (чтобы не поднимать снова)

- Drizzle на Фазе 1 (можно revisit ADR позже).  
- Soft-delete / archive-колонка как обязательный DoD Prototype.  
- Сырой SQL как основной слой доступа.  
- Шаринг `@prisma/client` в `apps/web`.
