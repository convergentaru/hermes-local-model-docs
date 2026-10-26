# Hermes prompt: запуск Project Atlas

**Важно:** Project Atlas — не отдельный репозиторий и не установленный skill. Это папка внутри публичного репозитория `convergentaru/hermes-local-model-docs`.

## Точная точка входа

- GitHub: https://github.com/convergentaru/hermes-local-model-docs/blob/main/docs/hermes/project-atlas/START.md
- Raw-файл для прямого чтения: https://raw.githubusercontent.com/convergentaru/hermes-local-model-docs/main/docs/hermes/project-atlas/START.md

## Промпт для Hermes

Не ищи «Project Atlas» в списке репозиториев или в `hermes skills list`. Не клонируй всю домашнюю папку и не загружай все инструкции в контекст.

1. Открой **точно указанный raw-файл START.md** через доступный GitHub fetch или терминал.
2. Прочитай только START.md и текущий этап.
3. Действуй по очереди, загружая следующий файл только после checkpoint предыдущего этапа:
   - `00-discovery.md`
   - `10-audit.md`
   - `20-video.md`
   - `30-memory.md`
   - `40-report.md`
   - `50-implementation.md`
4. Продолжай автоматически между этапами. Сохраняй checkpoint локально. После сбоя продолжай с последнего незавершённого этапа, не повторяя весь аудит.
5. Не создавай новые базы, репозитории или skills, пока не проверишь существующие.
6. Если точный URL не открывается, выполни одну проверку через терминал:
   `curl -fL --max-time 20 https://raw.githubusercontent.com/convergentaru/hermes-local-model-docs/main/docs/hermes/project-atlas/START.md`
   Если запрос не удался, сообщи точную ошибку. Не придумывай другой путь и не начинай настройку GitHub заново.

**Начни сейчас с этапа 00.** Выполняй безопасную работу последовательно; сохраняй краткий прогресс и реальный результат каждого этапа.


Если Hermes сообщает, что сессия занята другим процессом, используй отдельное окно/новую независимую сессию и сначала прочитай [промпт самовосстановления](PROJECT-ATLAS-RECOVERY-PROMPT.md). Не возобновляй ту же заблокированную сессию параллельно.
