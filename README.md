# DPline

Аналог task manager про дисциплину (игра слов вокруг *Discipline* без четырёх букв в середине).

**Память проекта и план:** каталог [`plan/`](./plan/README.md) — с чего начать, roadmap, бэклог, формат работы с ИИ, шаблон ADR и сессий.

## Локальный запуск (монорепа)

Структура: `apps/web`, `apps/api`, позже `packages/*`. Тулчейн — [ADR-001](./plan/decisions/001-monorepo-tooling.md): **pnpm 9 + workspaces**, без Turborepo.

### Требования

- **Node** 20.x LTS (`node -v` → например `v20.18.0`)
- **pnpm** 9.x (`pnpm -v` → `9.15.9`)

Установка pnpm (если ещё нет):

```bash
npm install -g pnpm@9.15.9
# или: brew install pnpm  — убедись, что версия 9.x, не 11
```

### Установка и проверка

Из корня репозитория:

```bash
pnpm install
pnpm list -r --depth -1
```

В списке должны быть `dpline-task-manager`, `@dpline/web` и `@dpline/api`.

### Scripts (пока заглушки)

```bash
pnpm dev    # параллельно scripts в apps (TODO #11 / #12)
pnpm build  # сборка workspace
```

Полноценный API (`/health`) — [#11](https://github.com/skv0r/dpline-task-manager/issues/11), Vite+React — [#12](https://github.com/skv0r/dpline-task-manager/issues/12).
