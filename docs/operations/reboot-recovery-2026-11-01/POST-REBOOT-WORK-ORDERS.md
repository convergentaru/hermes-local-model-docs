# Post-reboot work orders — 2026-11-01

Status: PLANNED. This document records the user's instructions for the next session. It is not evidence that any post-reboot process or task has run.

## 1. First action after reboot

1. Read `SESSION_BOOTSTRAP.md`, `AGENTS.md`, `docs/operations/SHARED-MEMORY-PROTOCOL.md`, `CURRENT_STATE.md`, `NEXT_ACTION.md`, and this recovery folder's `README.md` plus this file.
2. Take the read-only post-boot snapshot from `README.md` before starting agents or model servers.
3. Preserve the known-good baseline: Qwen3.5-9B, 160K target context, Unsloth as the model lifecycle manager. Do not launch `llama-server` directly, duplicate the model, change settings, or kill unexpected processes.
4. Paperclip and Hermes Gateway have previously been planned for service autostart, but their live post-reboot status must be checked. Do not assume Paperclip is installed, configured, enabled, or healthy merely because it was previously discussed.

## 2. Separate work orders — do not run both agents together initially

The user explicitly wants separate activation because the workstation has limited RAM/VRAM and previous combined/long-running work caused severe resource pressure. Current documented Unsloth baseline used `--parallel 1`; this means one inference request at a time. Separate activation means start one agent, let it work, save its checkpoint, stop/close that agent cleanly, then start the other. It does NOT mean launching a second model server or loading a second copy of Qwen.

### Work order A — Hermes: finish the Russian SystemRescue documentation

Use the complete task prompt below in a fresh Hermes task/session after the post-boot baseline and Unsloth route have been verified.

**HERMES — ЗАВЕРШЕНИЕ ПОЛНОГО ПЕРЕВОДА SYSTEMRESCUE 13.02 НА РУССКИЙ ЯЗЫК**

Главная цель — завершить полный перевод документации SystemRescue 13.02 на русский язык. Не подменять выполнение переводов аудитом, планом или итоговым отчётом.

Рабочие каталоги:
- Оригиналы: `/home/oleg/sources/systemrescue-sources/`
- Переводы: `/home/oleg/sources/systemrescue-sources/manual_ru/`
- Roadmap: `/home/oleg/projects/acer-rescue-usb/docs/systemrescue-docs-ru/ROADMAP.md`

Перед работой:
1. Восстанови историю прежних задач и проверь текущие файлы. Не начинай перевод повторно поверх уже выполненного.
2. Найди ранее созданный skill `documentation-translation`; прочитай его основной файл и references `audit-checklist.md`, `terminology-reference.md`. Используй существующий skill, не создавай дубликат.
3. Сверь все исходные Markdown-файлы с соответствующими файлами в `manual_ru`. Предыдущий отчёт Hermes противоречив: не считай утверждение «24/24 переведены» достоверным без построчной проверки.
4. Особо проверь ранее отмеченные неполные файлы и пропуски, а также файлы, ранее ошибочно названные завершёнными. Сначала установи точный список по фактическим файлам и содержимому.

Правила перевода:
- Переводи весь отсутствующий текст без сокращений, пересказа и пропуска разделов.
- Сохраняй структуру Markdown, заголовки, списки, таблицы, ссылки, команды, пути, имена пакетов, код и технические значения.
- Не переводи команды, имена файлов, параметры CLI и идентификаторы.
- Соблюдай терминологию существующего skill/reference.
- Не перезаписывай оригиналы. Существующие переводы сохраняй; редактируй только соответствующие файлы внутри `manual_ru`.
- После каждого файла сравни оригинал и перевод, проверь полноту разделов, ссылки, code fences и форматирование.

Рабочий цикл для каждого файла:
1. Сверить оригинал и перевод.
2. Зафиксировать отсутствующие/неполные фрагменты.
3. Перевести их.
4. Сохранить файл.
5. Повторно сравнить весь файл.
6. Обновить roadmap точным статусом.
7. Перейти к следующему файлу.

Не завершай задачу после промежуточного аудита или отчёта. Если ограничение сессии/контекста мешает закончить всё за один запуск, сохрани точный checkpoint: завершённые файлы, незавершённый файл и строка/заголовок продолжения, затем продолжай в следующем запуске с этого места. Не заявляй о полном завершении, пока каждый исходный файл не имеет полного проверенного перевода.

Критерии DONE:
- Для каждого исходного документа существует соответствующий русский перевод.
- Все разделы и строки оригинала представлены.
- Каждый файл сравнён с оригиналом после перевода.
- Проверены Markdown, команды, ссылки, code fences и терминология.
- Roadmap соответствует фактическому состоянию.
- Итоговый отчёт содержит точное число файлов, пути, размеры/хеши и список оставшихся UNKNOWN/BLOCKED (если есть).

До полного завершения переводов не собирай ISO и не записывай USB.

### Work order B — Claude Code: SystemRescue USB engineering

Пользователь сообщил, что в практическом задании с rescue-флешкой Hermes давал очень низкий полезный результат (оценка пользователя: примерно 5–30%), тогда как Claude Code начал реально заниматься задачей флешки. Это пользовательское наблюдение, не независимый benchmark.

Поэтому на следующем этапе Claude Code — основной инженерный исполнитель по USB/bootability:
- восстановить состояние проекта `/home/oleg/projects/acer-rescue-usb`;
- определить точный текущий target: старый HP, не Acer и не RISC-V;
- исследовать исходный SystemRescue 13.02 и существующие производные ISO, build scripts, git status и фактические ошибки загрузки;
- продолжить read-only анализ и подготовить проверяемый план исправления;
- использовать SSH/reverse-SSH как первый удалённый доступ; не включать Tailscale на первом MVP;
- не собирать ISO и не записывать USB без отдельного явного разрешения пользователя.

Не поручать Claude Code повторять перевод документации, если это не требуется для конкретной инженерной задачи. Не смешивать его session/logs с Hermes translation session.

## 3. Paperclip — следующий организационный этап

Пользователь хочет перейти к Paperclip как к основе управления AI-компанией/командой, работающей с минимальным ручным участием. Цель — не просто запустить двух агентов, а организовать управляемую компанию из одного человека с агентными ролями, задачами, очередью, зависимостями, heartbeat/checkpoints, бюджетами/лимитами, журналом решений и контролем человеком.

Предварительное разделение ответственности:
- Пользователь: владелец/CEO, задаёт цели, разрешения и критерии приёмки.
- Paperclip: диспетчеризация задач, очередь, зависимости, статусы, heartbeat, история и контроль расходов/лимитов.
- Hermes: операционные задачи, исследование, память, документация и долгие процессы; в ближайшем запуске — перевод SystemRescue.
- Claude Code: инженерная разработка, репозитории, USB/ISO анализ, тесты и code review; в ближайшем запуске — инженерная работа по rescue USB.
- Unsloth + Qwen3.5-9B: единый локальный inference backend; не отдельная модель на каждого агента.

Порядок Paperclip:
1. После reboot сначала проверить фактическую установку, версию, состояние и конфигурацию Paperclip read-only.
2. Проверить, какие адаптеры реально установлены и поддерживают Hermes и Claude Code, куда они маршрутизируют запросы и используют ли существующий Unsloth endpoint.
3. Проверить persistence/resume, heartbeat, Stop/cancel, таймауты и безопасные лимиты.
4. Настроить очередность: Hermes и Claude Code не должны одновременно выполнять тяжёлые модельные задания при одном Unsloth slot. Разнести heartbeat/запуски по времени.
5. Начать с короткого пилота под наблюдением; только после успешных проверок рассматривать длительную/ночную автономную работу.
6. Не включать автоматическое выполнение destructive actions, запись USB/ISO, очистку файлов или изменение конфигураций без отдельного разрешения.

Пользователь пришлёт видео, которое, по его словам, показывает пример создания компании одним человеком. Видео ещё не получено и не изучено. Не приписывать ему содержание и не принимать по нему архитектурные решения до просмотра.

## 4. Правила остановки и checkpoint

- Один агент за раз на текущем baseline; не запускать параллельно две тяжёлые задачи.
- После завершения фазы сохранить артефакты, отчёт и точный next action в соответствующем GitHub-репозитории.
- Перед переключением агента убедиться, что его задача остановлена/сохранена и inference slot свободен.
- Не убивать общий Unsloth `llama-server` ради остановки клиента.
- Не завершать Paperclip heartbeat без обновления статуса задачи и комментария/checkpoint.
- Не считать задачу завершённой только потому, что CLI session или heartbeat закончился.
- Все изменения конфигурации, запуск ISO build и запись USB требуют отдельного согласования.
