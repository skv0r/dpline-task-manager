---
description: Создать issue в GitHub + карточка Project + обновить plan/backlog.md
---

# /gh-create-task

Ты выполняешь команду создания задачи DPline. **Не пиши прикладной код** — только диспетчеризация.

## Вход

Из сообщения пользователя после команды извлеки (если чего-то нет — спроси одним сообщением):

| Поле | Обязательно | Пример |
|------|-------------|--------|
| title | да | `ADR: пакетный менеджер` |
| type | да | `app` или `pr` |
| label | да | короткий slug: `docs`, `monorepo`, `gitverse` |
| phase | нет (default 0) | `0` |
| estimate | нет | `1` |
| status | нет (default Ready) | `Ready` или `IceBox` |
| body | нет | acceptance criteria |

## Действия

1. Убедись, что `gh` установлен и `gh auth status` ок. Если нет — скажи пользователю: `brew install gh && gh auth login` (scopes: `repo`, `project`, `read:project`).
2. Запусти из корня репо:

```bash
chmod +x scripts/gh/*.sh
scripts/gh/create-task.sh \
  --title "…" \
  --type app \
  --label docs \
  --phase 0 \
  --estimate 1 \
  --status Ready \
  --body "…"
```

3. Покажи пользователю: номер issue, URL, будущее имя ветки `type-N-label`.
4. `plan/backlog.md` уже обновит скрипт — проверь diff; если маркер авто-секции отсутствует, оставь как есть после sync.
5. Напомни: старт работы — `/gh-start-task N`. PR открывает **сам пользователь**.

## Имена веток (строго)

`{app|pr}-{номер}-{label}` — примеры: `app-13-docs`, `pr-12-gitverse`.
