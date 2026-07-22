# Автоматизация DPline (v1) — подробные шаги

Слой диспетчера: Cursor-команды + `gh` + Actions.  
Вы по-прежнему: **код → commit → push → open PR → правки после Bugbot → merge**.

`main` остаётся **default branch** на GitHub (главная на сайте). Рабочий поток — в `dev`. Закрытие issue при merge в `dev` делает workflow, **не** смена default.

---

## Где вы сейчас

Если ветка локально `app-1-docs` и есть незакоммиченные `scripts/`, `.cursor/commands/`, `.github/` — вы на **шаге A** ниже (ещё не в remote).

Чеклист прогресса:

- [ ] A. Залить автоматизацию в `dev` (этот PR)
- [ ] B. `gh auth login`
- [ ] C. Secret `GH_PROJECT_TOKEN`
- [ ] D. Включить Bugbot на репо
- [ ] E. Закрыть `#16` вручную (если ещё open)
- [ ] F. Прогнать тестовый цикл `/gh-create-task` → `/gh-start-task`

---

## Шаг A — залить код автоматизации в `dev`

Цель: чтобы команды и workflow жили на GitHub, а не только у вас на диске.

### A1. Проверить ветку и файлы

```bash
cd /Users/gregoryburenkov/dev/GitHub/dpline-task-manager
git branch --show-current
# ожидается: app-1-docs

git status
```

Должны быть новые/изменённые: `.cursor/`, `.github/`, `scripts/gh/`, `plan/guides/automation.md` и правки agreement/git-flow/backlog.

### A2. Коммит

```bash
git add .cursor/ .github/ scripts/ plan/
git status
git commit -m "docs: add GitHub task automation, Bugbot config, merge-to-dev workflow"
```

### A3. Пуш

```bash
git push -u origin app-1-docs
```

### A4. PR в `dev` (сами в UI)

1. Откройте ссылку из вывода push или:  
   https://github.com/skv0r/dpline-task-manager/compare/dev...app-1-docs  
2. **base:** `dev` (не `main`).  
3. Title например: `docs: GitHub task automation + Bugbot + merge workflow`.  
4. В body:

```text
## Summary
- Cursor commands /gh-create-task, /gh-start-task
- scripts/gh + backlog sync
- workflow: merge to dev → close issue + Project Done
- BUGBOT.md + guides/automation.md

Refs #1
```

5. Create pull request → Merge (как с `#18`).  
6. Project: карточку `#1` при желании → Review → после merge Done (или оставьте, если `#1` ещё не «всё»).

### A5. Подтянуть `dev` локально

```bash
git checkout dev
git pull origin dev
```

Опционально удалить локальную ветку задачи:

```bash
git branch -d app-1-docs
```

---

## Шаг B — авторизация GitHub CLI

`gh` уже ставили через brew; сейчас нужно войти.

```bash
gh auth login
```

В диалоге обычно:

1. **GitHub.com**  
2. **HTTPS** (удобно с тем же remote)  
3. Login with browser  
4. Когда спросит scopes / permissions — нужны права на **repo** и **project** (иногда «Enable SSO» не нужен для личного аккаунта).

Проверка:

```bash
gh auth status
gh issue list --repo skv0r/dpline-task-manager --limit 3
```

Если команды падают с 401/403 — повторите `gh auth login` и добавьте scope `project`:

```bash
gh auth refresh -s repo,project,read:project
```

---

## Шаг C — Secret для Project Done

Без этого: issue при merge в `dev` **закроется**, а колонка Project может **не** стать Done.

### C1. Создать PAT

1. GitHub → аватар → **Settings** → **Developer settings** → **Personal access tokens**.  
2. Classic: **Generate new token (classic)**  
   - Note: `dpline-project-actions`  
   - Scopes: `repo` (весь блок), `project` (или `read:project` + write если отдельно).  
3. Скопируйте токен **один раз**.

Fine-grained тоже ок: доступ к репо `dpline-task-manager` + Permissions: Issues R/W, Pull requests R, **Projects** R/W.

### C2. Положить в Secrets репо

1. https://github.com/skv0r/dpline-task-manager/settings/secrets/actions  
2. **New repository secret**  
3. Name: `GH_PROJECT_TOKEN` (точное имя — так ждёт workflow)  
4. Value: вставить PAT → Save

---

## Шаг D — Bugbot на репо

1. Откройте [cursor.com/dashboard](https://cursor.com/dashboard).  
2. Раздел **Bugbot** / **Integrations** / GitHub.  
3. Подключите GitHub-аккаунт `skv0r`, если ещё не подключён.  
4. Включите репозиторий **`skv0r/dpline-task-manager`**.  
5. Режим: авто на каждый PR (или «only once» — на ваш вкус; для учёбы удобен авто).  
6. В репо уже есть [`.cursor/BUGBOT.md`](../../.cursor/BUGBOT.md) — Bugbot подхватит после merge шага A.

**Про Pro $20:** обычно есть **лимит** бесплатных/включённых ревью; сверх — on-demand или отдельный Bugbot. Смотрите usage в dashboard, не рассчитывайте на безлимит.

Локально перед push (по желанию): в Agent наберите `/review` или `/review-bugbot`.

---

## Шаг E — добить хвост `#16`

Merge в `dev` **не** закрыл issue автоматически (default = `main`).

1. https://github.com/skv0r/dpline-task-manager/issues/16 → **Close**.  
2. Project → Status **Done**, Actual hours по желанию.

---

## Шаг F — тестовый цикл команд (после A+B)

Рабочее дерево чистое, вы на `dev`:

```bash
git checkout dev
git pull
git status   # должно быть clean
```

### F1. Создать тестовую задачу

В Cursor Agent: `/gh-create-task` → агент пришлёт **один** опрос → вы отвечаете **одним** сообщением, например:

```text
B
B
Практика: проверка команд
E
A
A
A
```

(= pr, IceBox, title, label=gh-commands, phase=0, estimate/body skip) → сразу создаётся issue.

Ожидание: новый issue, карточка на доске, строка в `plan/backlog.md` (секция `backlog:auto`).

Если агент не видит `/gh-create-task` — команда из `.cursor/commands/` появляется после того, как файлы уже в воркспейсе (после шага A5). Перезапуск чата иногда помогает.

### F2. Старт задачи

Подставьте реальный номер, например `21`:

```text
/gh-start-task 21
```

Ожидание:

- Project → **In Progress**, **Start date** = сегодня  
- локальная ветка `pr-21-autotest`  
- вы на этой ветке  

### F3. Мини-изменение → PR → merge

```bash
# например одна строка в plan/sessions/ или README тестовый
git add -A
git commit -m "chore: automation smoke test"
git push -u origin HEAD
```

Сами откройте PR: **base `dev`**, body:

```text
Closes #21
```

Дождитесь комментариев Bugbot (если включён) → Merge.

### F4. Проверить автоматику после merge

- Issue `#21` → **Closed** (workflow).  
- Project → **Done**, **Target date** = сегодня (дата закрытия; если secret ок).  
- Actions: вкладка Actions репо → workflow **On PR merged to dev** → зелёный.

Если issue закрылся, а Done нет — проверьте `GH_PROJECT_TOKEN` и имена колонок (`Done` точно так же, как на доске).

Потом тестовую ветку можно удалить; карточку оставить в Done как учебный артефакт или удалить issue из project.

---

## Повседневный цикл (когда всё настроено)

```text
1. В чате: /gh-create-task …        → корневой issue + Project + backlog
1b.В чате: /gh-create-subtask …     → sub-issue под #parent (можно и под другим sub-issue)
2. В чате: /gh-start-task N         → In Progress + Start date + ветка type-N-label
3. Вы: код
4. Вы: commit + push
5. Вы: open PR → base=dev, Closes #N
6. Bugbot: комментарии → вы правите → push
7. Вы: Merge
8. Actions: close + Done + Target date (дата закрытия)
9. В чате: ассистент пишет plan/sessions/… + push (сессия не без push)
```

---

## Команды — детали

Файлы: `.cursor/commands/gh-create-task.md`, `gh-create-subtask.md`, `gh-start-task.md`.

### `/gh-create-task`

Скрипт: `scripts/gh/create-task.sh`

**UX:** один опрос в чате → один ответ → сразу создание (без пошаговых вопросов).

Параметры (из ответа на опрос):

| Поле | Обязательно | Пример |
|------|-------------|--------|
| title | да | `ADR: тулчейн` |
| type | да | `app` \| `pr` |
| label | да | `monorepo` (slug) |
| phase | нет | `0` |
| estimate | нет | `2` |
| status | нет | `Ready` \| `IceBox` |
| body | нет | acceptance |

Имя будущей ветки: `{type}-{номер}-{label}`.

### `/gh-create-subtask`

Скрипт: `scripts/gh/create-subtask.sh` (= `create-task.sh --parent N`).

Тот же UX «один опрос → сразу», плюс обязательный **parent** (номер issue или уже существующего sub-issue для вложенности).

Пример ответа:

```text
10
A
A
Пустой api с /health
C
A
C
A
```

### `/gh-start-task N`

Скрипт: `scripts/gh/start-task.sh N`

Требование: **чистый** working tree. Иначе скрипт остановится — сначала commit/stash.

---

## Имена веток (строго)

`{app|pr}-{номер}-{label}`

| Пример | Смысл |
|--------|--------|
| `app-13-docs` | продукт, #13, docs |
| `pr-12-gitverse` | практика #12 |

---

## Скрипты (справка)

| Скрипт | Назначение |
|--------|------------|
| `scripts/gh/create-task.sh` | создать задачу (`--parent` опционально) |
| `scripts/gh/create-subtask.sh` | sub-issue (обязателен `--parent`) |
| `scripts/gh/start-task.sh` | старт + ветка |
| `scripts/gh/sync-backlog.py` | open issues → backlog auto-секция |
| `scripts/gh/on-pr-merged-dev.sh` | close + Done (вызывает CI) |
| `.github/workflows/on-pr-merged-dev.yml` | триггер на merge в `dev` |

Ручной sync backlog:

```bash
python3 scripts/gh/sync-backlog.py
```

---

## Ограничения v1

- Имена option в Project (`App`/`Prac`, `IceBox`, `Done`…) должны совпадать со скриптом; иначе warn и правка руками.  
- Bugbot на Pro — не безлимит.  
- PR открываете только вы.  
- Пустые remote-ветки заранее не создаём.  
- Текст session.md пишет ассистент, не Actions.

---

## Если что-то сломалось

| Симптом | Что проверить |
|---------|----------------|
| `gh: not logged in` | шаг B |
| команда `/gh-*` не в списке `/` | файлы в `.cursor/commands/` на текущей ветке; новый чат |
| `working tree not clean` на start | commit или `git stash` |
| issue не закрылся после merge | workflow в Actions; в PR есть `Closes #N`; merge именно в `dev` |
| Done не ставится | secret `GH_PROJECT_TOKEN`; имя колонки `Done` |
| Bugbot молчит | dashboard: репо включён; лимит usage; автор PR = тот же GitHub, что связан с Cursor |
