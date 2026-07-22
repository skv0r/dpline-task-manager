---
description: Создать sub-issue под существующим issue (один опрос → сразу)
---

# /gh-create-subtask

Только диспетчеризация. **Не пиши прикладной код.**

Создаёт **дочернюю** задачу (GitHub sub-issue) под уже существующим issue — в том числе под другим sub-issue (вложенность до лимита GitHub).

## Правило токенов

**Один** опрос → **один** ответ → сразу скрипт. Без пошаговых вопросов.

Если в сообщении уже есть `parent` + `title` + `type` + `label` — опрос не нужен.

---

## Сообщение-опрос (одним блоком)

```markdown
### /gh-create-subtask — одним ответом

**0. parent** — номер родительского issue (обязательно), напр. `10` или `1`  
  (можно указать и номер существующего sub-issue — будет вложенный уровень)

**1. type** — `A` app | `B` pr  
**2. status** — `A` Ready (default) | `B` IceBox  
**3. title** — одна строка  
**4. label** — slug ИЛИ: `A` docs | `B` monorepo | `C` health | `D` autotest | `E` gh-commands | `F` gitflow | свой slug  
**5. phase** — `A` 0 (default) | `B` 1 | число  
**6. estimate** — `A` skip | `B` 0.5 | `C` 1 | `D` 2 | число  
**7. body** — `A` skip | текст  

Пример:
```
10
A
A
Пустой api с /health
C
A
C
A
```
```

---

## Действия

1. `gh auth status` ок.
2. Из корня:

```bash
chmod +x scripts/gh/*.sh
scripts/gh/create-subtask.sh \
  --parent 10 \
  --title "…" \
  --type app \
  --label health \
  --phase 0 \
  --status Ready
```

(или `create-task.sh … --parent 10`)

3. Покажи: `#N`, parent `#P`, URL, ветка `type-N-label`.
4. Напомни: `/gh-start-task N`; PR — пользователь.

## Ветки

Строго `{app|pr}-{номер}-{label}` — номер **дочернего** issue, не родителя.
