# NEXT_ACTION — один следующий шаг

Дата: 2026-10-31

## Приоритет: сначала проверить slots, не начинать общий тюнинг вслепую

Рабочая гипотеза пользователя: возможно, для двух агентов достаточно одного llama-server с одной загруженной Qwen3.5-9B и двумя параллельными slots. Проверить это по фактической конфигурации и тестом. Не менять конфигурацию до baseline.

## Два независимых задания, которые нельзя смешивать

### Hermes — перевод

- Hermes занимался отдельной задачей перевода.
- Последнее сообщение Hermes: `Gateway disconnected; turn outcome is unknown`.
- WebSocket оборвался с `ConnectionClosedError: keepalive ping timeout`.
- Hermes сообщил, что нужно возобновить напечатанную session ID, чтобы проверить, завершилось ли задание или было прервано.
- **Не отправлять перевод повторно**, пока не проверен исходный session ID и состояние результата.
- Эта ошибка сама по себе не доказывает неисправность llama-server.

### Claude Code — аудит контекста

- Claude Code отдельно выполнял аудит контекстного окна и Auto-Compact.
- Он сообщил: `Autocompact is thrashing: the context refilled to the limit within 3 turns of the previous compact, 3 times in a row.`
- Были прочитаны `.claude.json`, Hermes runtime `server.json`, `presets.ini` и `QWEN_AUDIT_REPORT.md` (385 строк); также был открыт файл credential с API-ключом — секреты не копировать в отчёты.
- Не запускать новый параллельный аудит в том же сеансе, пока Claude Code не вернётся к приглашению ввода и не будет сохранён промежуточный результат.
- Следующий шаг для Claude Code: сохранить краткий `CONTEXT_AUDIT_PROGRESS.md`, затем продолжить проверку малыми порциями.

## Очерёдность следующей рабочей сессии

1. Проверить исход Hermes translation session по напечатанному session ID; не дублировать работу.
2. Получить и сохранить итог/промежуточный отчёт Claude Code по текущему аудиту контекста.
3. T-005 — read-only исследование и проверка одного llama-server с двумя slots для двух независимых агентов. Сначала зафиксировать текущую конфигурацию; не запускать вторую копию Qwen.
4. Если slots-схема подтверждена и эксперимент проходит, спланировать безопасное объединение маршрутизации двух клиентов к одному endpoint. Только после согласования менять конфигурацию.
5. T-004 — разобраться с Auto-Compact thrashing и размером контекста уже в целевой архитектуре.
6. T-001/T-002 — оставшуюся диагностику и настройку выполнять по необходимости, не дублируя проверки, уже покрытые T-005.
7. После каждого этапа сохранять подтверждённые факты в журнале.

Полный список: [TASKS.md](TASKS.md).

## Техническое уточнение по slots

- `--parallel N` / `n_parallel` задаёт число параллельных серверных slots, а не число загруженных моделей.
- Slots позволяют одному экземпляру сервера обслуживать несколько запросов; они не означают бесплатную память: активные последовательности используют KV cache и вычислительные ресурсы.
- Не считать, что каждый slot автоматически получает полный `--ctx-size`. Семантика общего контекста и per-slot context зависит от параметров и версии сборки; проверить `--kv-unified-per-slot` и фактический `/slots`.
- Unsloth Studio управляет числом slots через `n_parallel`; его VRAM fitter может запустить меньше slots, чем запросил пользователь. Проверять фактическое значение после загрузки.
- Slots обычно назначаются сервером свободным запросам динамически; отдельное постоянное закрепление агента за номером slot не предполагать без подтверждения API.

## Последнее известное состояние (не считать актуальным без проверки)

- Hermes llama-server ожидался на `:18434`; в предыдущем рабочем состоянии пользователь останавливал `llama-server.service`.
- Unsloth worker ранее слушал `:52681`, но этот порт динамический и мог измениться.
- В прежней конфигурации Unsloth были `--parallel 4`, `-c 65536`, `--kv-unified`, `--slot-save-path`, `--ctx-checkpoints 5`.
- Не запускать вторую копию Qwen, не удалять модели/профили/credentials, не менять context/offload/slots без проверки реального профиля и памяти.

## Правила

- Hermes перевод и Claude Code аудит — независимые задания.
- Не смешивать их session ID, логи, результаты и команды.
- Не повторять неизвестно завершившуюся работу до проверки состояния.
- Никаких изменений конфигурации без согласования.
- Не публиковать API-ключи, токены и credential-файлы.

## Уточнение: одна модель, несколько slots и загрузка нескольких моделей — разные механизмы

По итогам обсуждения 2026-10-31 зафиксировать отдельно:

- **Одна загруженная модель + несколько slots:** один процесс llama-server держит одну копию весов Qwen3.5-9B и может обслуживать несколько независимых запросов через slots. Количество slots задаётся параметрами вроде `--parallel N` / `n_parallel`. Slot — это рабочий контекст/канал обработки запроса, а не ещё одна загруженная модель.
- **Несколько загруженных моделей:** это отдельная функция управления памятью Unsloth Studio. Переключатель **Keep multiple models loaded** разрешает держать в памяти несколько разных моделей. Он не создаёт slots и не нужен для схемы «одна модель — два агента».
- Следовательно, если цель — Hermes и Claude Code на одной Qwen, надо проверять число реально работающих llama-server процессов, загруженные ими model path и фактическое число slots. Наличие пункта интерфейса «загрузить две модели» само по себе не означает, что для двух агентов нужны две модели.
- Пока не установлено, какой именно компонент/процесс загружает вторую модель и какую именно. Это остаётся вопросом для read-only аудита; не делать вывод по одному экрану Unsloth и не останавливать процессы наугад.

### Зафиксированные предпочтения конфигурации Unsloth (не менять без отдельного решения)

- Custom llama.cpp folder: `/home/oleg/llama.cpp/build-cublas/bin`.
- Модель: `/home/oleg/.hermes/models/Qwen3.5-9B-Q4_K_M.gguf`.
- **Keep model in GPU memory: ON**.
- **Keep multiple models loaded: OFF** — не держать несколько разных моделей одновременно.
- **Idle auto-unload: 0**.
- **Switch model by request: OFF**.
- Не запускать дополнительные экземпляры llama-server и не проводить переустановки/тесты без отдельного согласования.

### Вывод для следующего этапа

Проверять архитектуру «одна копия Qwen + два slots + два клиента», а не включать загрузку нескольких моделей. Сначала только зафиксировать фактические процессы, model path, endpoints, `n_parallel` и ответ `/slots`; затем отдельно согласовать короткий тест двух независимых запросов. Историю и tool state Hermes и Claude Code держать раздельно.


---

## Latest superseding note — 2026-10-31

Older items proposing a new two-server/two-agent slots investigation are historical and have been superseded by the successful shared-server setup recorded in `SESSION_BOOTSTRAP.md`. Do not reopen that work unless a new failure or requirement appears.

### Current next action
1. Recover the prior Hermes SystemRescue translation session using `session_search` for `SystemRescue`, `systemrescue-help-original`, translation and Russian help ISO.
2. Check actual `/usage` and compression telemetry; do not repeat the unsupported claim of a hard 70K context cap.
3. Do not rerun translation until the previous session/result has been checked.

### Hermes ↔ Claude Code
Research is recorded in `docs/integrations/hermes-claude-code.md`. No additional integration is planned now. Keep the two clients independent for Screenlife comparisons; revisit one-way MCP Serve only for a concrete use case.


---

## Latest next action — SystemRescue translation output verification (2026-10-31)

The Hermes session-recovery report has arrived. Do not ask the user to repeat task context and do not rerun translation.

First inspect subagent session `20261028_133323_20e490` and parent `20261028_132200_f170ad` for the eight source/output filenames, exact absolute output directory, file sizes, hashes and success/failure details. Confirm that every output file exists and is non-empty. Then compare the local artifacts and decide what reviewed text files should be committed to `convergentaru/pc-rescue-platform`.

Do not overwrite or regenerate translations. Do not build an ISO until output files have been recovered, reviewed and archived.

Detailed audit: https://github.com/convergentaru/pc-rescue-platform/blob/main/docs/SYSTEMRESCUE-TRANSLATION-RECOVERY-AND-CONTEXT-AUDIT-2026-10-31.md
