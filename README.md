# DPline

Аналог task manager про дисциплину (игра слов вокруг *Discipline* без четырёх букв в середине).

**Память проекта и план:** каталог [`plan/`](./plan/README.md) — с чего начать, roadmap, бэклог, формат работы с ИИ, шаблон ADR и сессий.

## Локальный запуск (монорепа)

Структура: `apps/web`, `apps/api`, позже `packages/*`. Тулчейн — [ADR-001](./plan/decisions/001-monorepo-tooling.md): **pnpm 9 + workspaces**, без Turborepo.

> Используй только **pnpm** из корня репозитория (`pnpm install`). Не запускай `npm i` — сломает workspace.

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

### Scripts

```bash
pnpm dev         # web + api параллельно
pnpm build       # сборка workspace
pnpm lint        # ESLint (сейчас web)
pnpm typecheck   # tsc по apps/*
```

### API (health)

```bash
pnpm --filter @dpline/api dev
curl -s http://localhost:3001/health
# → {"status":"ok"}  на http://localhost:3001
```

### Web

```bash
pnpm --filter @dpline/web dev
# → http://localhost:5173  (страница DPline)
```

### CI

На PR и push в `dev` / `main` workflow [`.github/workflows/ci.yml`](./.github/workflows/ci.yml) гоняет `pnpm lint` и `pnpm typecheck`.
