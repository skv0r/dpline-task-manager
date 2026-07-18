---
description: In Progress в Project + локальная ветка type-N-label от dev
---

# /gh-start-task

Ты стартуешь работу над issue. **Не пиши прикладной код** в этой команде — только git/Project.

## Вход

Номер issue из сообщения: `/gh-start-task 20` или `/gh-start-task-20` → `20`.
Опционально: `--label docs` если в теле issue нет meta label.

## Действия

1. Working tree должен быть чистым; если нет — остановись и попроси commit/stash.
2. Выполни:

```bash
chmod +x scripts/gh/*.sh
scripts/gh/start-task.sh 20
```

(подставь номер)

3. Сообщи: ветка `type-N-label`, Status=In Progress, ссылка на issue.
4. Дальше пользователь: код → `commit` → `push -u origin HEAD` → **сам** открывает PR в **base=`dev`**.
5. В PR body должно быть `Closes #N` (для истории) — закрытие при merge в `dev` делает workflow `.github/workflows/on-pr-merged-dev.yml`.
6. Напомни про Bugbot на PR и локально `/review` перед push при желании.

## Имена веток (строго)

`{app|pr}-{номер}-{label}` — не `app-13fr`, не `pr16gitflow`.
