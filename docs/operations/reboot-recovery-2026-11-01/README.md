# Протокол восстановления после перезагрузки — 2026-11-01

**Назначение:** сохранить проверенные факты, историю решений и незакрытые вопросы по локальной AI-инфраструктуре Ubuntu 26 и связанной задаче SystemRescue. Этот документ — точка продолжения после reboot, а не утверждение о текущем live-состоянии компьютера.

**Правило достоверности:** VERIFIED означает, что результат подтверждён фактическим выводом/тестом; OBSERVED — параметр был замечен в конкретном снимке; HISTORICAL — старое значение, не использовать как текущее; UNKNOWN — не установлено; PLANNED — ещё не выполнено. Не превращать предположения в факты и не переписывать историю задним числом.

## 1. Компьютер и ограничения ресурсов

- ОС: Ubuntu 26, рабочий стол i3 на X11.
- GPU: NVIDIA GeForce RTX 3060, 12 GB VRAM.
- Системная RAM: около 12 GB; swap: 4 GB.
- Основная модель: `Qwen3.5-9B-Q4_K_M.gguf`.
- Файл модели: `/home/oleg/.hermes/models/Qwen3.5-9B-Q4_K_M.gguf`.
- Целевой контекст текущей конфигурации: 160000 токенов. Не предлагать уменьшать его без отдельного измерения, обоснования и согласования.
- Ограниченные RAM/VRAM — реальный фактор. Не предполагать, что модель, второй сервер или второй агент «поместятся» без замера.
- Не скачивать/не переключать модель и не менять архитектуру в рамках восстановления после reboot.

## 2. Принятая архитектура (последний подтверждённый базовый вариант)

Целевая схема, успешно проверенная 2026-10-31:

1. Одна загруженная копия Qwen3.5-9B.
2. Один Unsloth-managed `llama-server`.
3. Unsloth API wrapper: `http://127.0.0.1:8888/v1`.
4. Контекст запуска: `160000`.
5. `--parallel 1`: один inference slot; запросы клиентов обслуживаются последовательно, это не параллельная генерация.
6. Hermes — отдельный клиент через Custom OpenAI-compatible Chat Completions.
7. Claude Code — отдельный клиент через Anthropic-compatible маршрут Unsloth, запуск к уже работающему серверу: `unsloth start claude --no-serve`.
8. Сессии, память, инструменты и роли Hermes и Claude Code независимы. Общая только модель/inference backend.

**Важно:** агент, Gateway, API wrapper, llama-server и загруженные веса — разные компоненты. Остановка агента не доказывает остановку сервера или выгрузку модели. Остановка сервера не равна остановке Gateway.

### Проверенные функциональные тесты 2026-10-31

- Unsloth model load + OpenAI-compatible API: HTTP 200 и реальная генерация.
- Hermes CLI Custom → Unsloth: ответ `HERMES_UNSLOTH_OK`.
- Claude Code 2.1.286 через `unsloth start claude --no-serve`: ответ `CLAUDE_UNSLOTH_OK`.
- После отключения legacy Hermes router API Unsloth снова проверен: модель Qwen указана как loaded, запрос вернул `UNSLOTH_AFTER_ROUTER_STOP_OK`.
- Hermes Gateway user service оставался active.
- В том конкретном снимке `pgrep -xc llama-server` вернул `1`.

Эти тесты подтверждают работу на момент выполнения 2026-10-31, но не доказывают, что после последующих экспериментов или reboot всё осталось в том же состоянии.

## 3. Порты и процессы: не путать историю с текущим состоянием

| Значение | Назначение / статус |
|---|---|
| `127.0.0.1:8888` | Unsloth API wrapper; подтверждённый внешний endpoint в рабочем снимке 2026-10-31 |
| внутренний порт Unsloth `53815` | HISTORICAL; динамический порт одного запуска |
| внутренний порт Unsloth `55831` | HISTORICAL; динамический порт другого снимка |
| внутренний порт Unsloth `46623` | HISTORICAL; наблюдался в более позднем эксперименте, не считать постоянным |
| `:18434` | legacy Hermes router; его user service был отключён и проверен inactive/disabled 2026-10-31; не запускать в целевой схеме без отдельного решения |
| `:52681` | старый отдельный Unsloth/Claude эксперимент; HISTORICAL, не считать текущим |
| `:37961`, `:53993` | прежние значения из истории port drift; HISTORICAL |

PID и внутренний порт Unsloth динамические. Не вписывать их в постоянные launch scripts и не использовать как критерий готовности.

### Legacy Hermes router :18434

Исторически были два процесса с именем `llama-server`:
- Hermes router на `:18434`, с `--models-max 1 --models-autoload` и presets;
- Unsloth server с Qwen на динамическом внутреннем порту.

Read-only запрос к router API показал, что все семь preset-моделей, включая Qwen3.5-9B, имели статус `unloaded`. Затем пользователь выполнил:

```bash
systemctl --user disable --now llama-server.service
```

Пользователь подтвердил: legacy unit inactive/disabled, Hermes Gateway active, точное число процессов `llama-server` стало 1. Unit-файл и presets не удалялись. Это подтверждённое историческое действие, но после reboot повторно проверить состояние; не выполнять команду вслепую.

## 4. Последний эксперимент загрязнён — не считать его чистой базой

После успешной конфигурации пользователь случайно запустил второй вариант сервера/запуска Hermes. В результате:
- неизвестно, появился ли второй процесс `llama-server`;
- неизвестно, был ли создан новый внутренний порт;
- неизвестно, загружалась ли вторая копия модели или только стартовал router/обёртка;
- неизвестно, какой дополнительный расход RAM/VRAM возник;
- неизвестно, остались ли фоновые процессы или сервисы после эксперимента.

Пользователь сообщил о ночном эпизоде сильной нагрузки/зависания; к утру агенты уже были выключены. Возможное исчерпание RAM/swap или VRAM — гипотеза, не установленная причина. Не утверждать, что OOM доказан, пока не прочитаны kernel logs и метрики.

**План пользователя:** перезагрузить компьютер и повторить эксперимент с чистого исходного состояния. После reboot сначала только read-only снимок. Не запускать Hermes, Claude Code, Unsloth или второй вариант сервера до фиксации базового состояния.

## 5. Существующие launch scripts — проверять, не дублировать

По предыдущей локальной работе уже создавались:
- `~/.local/bin/ai-hermes`
- `~/.local/bin/ai-claude`
- `~/.local/bin/ai-both`
- общий модуль `~/.local/libexec/ai-launch-common.sh`
- ярлыки в `~/.local/share/applications/` и копии на рабочем столе.

Это известные ранее созданные файлы, но их актуальное содержимое, executable bit, desktop-entry trust и работоспособность после reboot не проверены. Не создавать новые скрипты/ярлыки и не переписывать существующие, пока не сделан read-only просмотр. Пользователь сообщает, что копии на рабочем столе выглядят как обычные файлы и не запускаются; это отдельный незакрытый вопрос.

Скрытые каталоги в домашней папке отображаются сочетанием Ctrl+H. `~/.local` — скрытая папка.

## 6. Первая операция после reboot: только read-only snapshot

Сначала получить снимок RAM/GPU/процессов/портов/сервисов и журнал OOM. Ничего не запускать и не останавливать. Команды ниже только читают состояние:

```bash
echo '=== BOOT / OS ==='
date -Is
uptime
uname -a

echo '=== MEMORY ==='
free -h
swapon --show

echo '=== GPU ==='
nvidia-smi
nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv

echo '=== EXACT LLAMA SERVER PROCESSES ==='
pgrep -ax llama-server || true
printf 'llama-server count: '
pgrep -xc llama-server || true

echo '=== RELEVANT PROCESSES ==='
pgrep -af 'hermes|claude|unsloth|llama-server' || true

echo '=== LISTENING TCP PORTS ==='
ss -lntp

echo '=== USER SERVICES ==='
systemctl --user --no-pager --type=service --state=running
systemctl --user status hermes-gateway.service --no-pager -l || true
systemctl --user status llama-server.service --no-pager -l || true

echo '=== CURRENT BOOT OOM EVENTS ==='
sudo journalctl -k -b 0 --no-pager | grep -Ei 'out of memory|oom-kill|killed process|memory cgroup out of memory' | tail -100 || true

echo '=== PREVIOUS BOOT OOM EVENTS ==='
sudo journalctl -k -b -1 --no-pager | grep -Ei 'out of memory|oom-kill|killed process|memory cgroup out of memory' | tail -100 || true

echo '=== EXISTING LAUNCH SCRIPTS (READ ONLY) ==='
for f in "$HOME"/.local/bin/ai-* "$HOME"/.local/libexec/ai-*; do
  [ -f "$f" ] || continue
  echo "--- $f"
  stat -c 'mode=%A size=%s modified=%y' "$f"
  sed -n '1,240p' "$f"
done
```

Если после reboot нет старых логов `-b -1`, это не доказательство отсутствия OOM; проверить доступные boot journal и дату инцидента. Не печатать API keys, токены и содержимое `.env`. При публикации вывода удалять секреты и приватные данные.

**Критерий чистой базы:** до запуска агентов/модели зафиксированы число llama-server процессов, свободная RAM/swap, GPU memory, listening ports и активные user services. Если обнаружен неожиданный сервер, не убивать его — сначала определить unit/родителя/аргументы и состояние загруженных моделей.

## 7. Контролируемый эксперимент после базового снимка

Эксперимент проводить по одному изменению за раз, сохраняя output после каждого шага:

1. Зафиксировать исходный idle state после reboot.
2. Запустить только Unsloth через уже проверенный механизм `unsloth` и подтверждённую команду/профиль. Не запускать прямой `llama-server`.
3. Проверить один процесс сервера, API wrapper, модель loaded, context 160000, `--parallel 1`, RAM/swap и VRAM.
4. Проверить короткую генерацию через API.
5. Подключить только одного агента; проверить его ответ и повторить inventory.
6. Остановить именно агента и повторить inventory. Отдельно зафиксировать, что стало с сервером и моделью.
7. Только после фиксации результата подключать второго клиента к уже существующему серверу через поддерживаемый `--no-serve` маршрут, если он нужен.
8. Не запускать второй Hermes/второй server variant, пока не доказано, что это не создаёт отдельный inference process, не конфликтует с Gateway/session и не загружает вторую модель.
9. Отдельно проверить остановку Unsloth server и фактическое освобождение VRAM/RAM. Не путать её с остановкой агента.
10. Не оставлять оба агента или экспериментальную конфигурацию работать на ночь до проверки длительной стабильности и OOM telemetry.

Нельзя использовать `pkill llama-server` для остановки одного агента: это может убить общий inference backend. Не делать массовые stop/kill действия.

## 8. Проверенная команда запуска Unsloth — исторический reference, не запускать автоматически

Пользователь ранее запускал Unsloth CLI (версия 2026.10.11) командой:

```bash
unsloth run \
  --model "/home/oleg/.hermes/models/Qwen3.5-9B-Q4_K_M.gguf" \
  --context-length 160000 \
  --gpu-memory-mode manual \
  --parallel 1 \
  --port 8888 \
  --host 127.0.0.1 \
  --disable-tools
```

В другом подтверждённом снимке встречался вариант с `--api-only` вместо `--disable-tools`. Не смешивать варианты и не угадывать флаги. Перед повторным запуском проверить фактическую установленную версию и сохранённый рабочий профиль/скрипт; предпочтительно восстановить уже известный рабочий способ через Unsloth. Не подменять его прямым самостоятельным запуском `llama-server`.

Hermes Custom endpoint ранее был:
- Base URL: `http://127.0.0.1:8888/v1`
- API mode: Chat Completions
- Model: `Qwen3.5-9B-Q4_K_M`
- Context: `160000`
- ключ хранится в `~/.hermes/.env`; значение никогда не публиковать.

Claude Code ранее подключался командой `unsloth start claude --no-serve`. Семантику команд `unsloth start hermes --no-serve --persist` и повторного запуска Hermes в текущей установленной версии считать **непроверенной** до проверки CLI help/source и реального процесса. Не утверждать заранее, создаст ли второй Hermes второй server или только клиента/Gateway.

## 9. SystemRescue USB — отдельный проект, связанный инцидент

Проектная локальная папка: `/home/oleg/projects/acer-rescue-usb`. Текущий USB test target — старый Hewlett-Packard (HP), не Acer и не RISC-V. Основной Ubuntu 26 computer — отдельная машина; не путать его с физическим HP для загрузочного теста.

- Базовый оригинальный ISO ранее: `build/systemrescue-13.02-amd64.iso`.
- В истории существуют несколько производных ISO, включая `acer-rescue-v6-final.iso`, `acer-rescue-mvp-20261024-v6-merged.iso`, `acer-rescue-v6-final-before-service-20261024-214219.iso`, `acer-rescue-tailscale-mvp-v6.iso`. Наличие файлов и их актуальные hashes после reboot не проверены.
- Недавний вариант ISO/USB, подготовленный Hermes/Claude, не загрузился на HP. Точная причина пока не установлена.
- Известные направления расследования: исходный ISO vs производный ISO, BIOS/UEFI, El Torito catalog, EFI boot image/partition, bootloader files, параметры сборки, checksum, build logs и реальные сообщения HP.
- Ранее возникали подозрения о неверном параметре `genisoimage --boot-info-text`, ошибочном wrapper exit code и некорректной проверке SHA256. Это гипотезы из прежнего инцидента; подтвердить по фактическим логам, не записывать как установленную причину.
- Предпочтительный первый этап удалённого доступа: SSH/reverse-SSH; Tailscale для этого этапа не включать.
- Сначала расследование и план. Не выполнять сборку ISO, запись USB, `dd`, `wipefs`, `mkfs`, удаление/перезапись оригиналов или изменение AI runtime без отдельного разрешения.
- QEMU не является критерием готовности. Нужен реальный тест загрузки USB на HP.
- Перевод справки SystemRescue 13.02 уже запускался в прежних Hermes sessions. Не запускать перевод заново, пока не найдены прежние outputs и не проверено, что именно сохранилось. Сохранять оригиналы; не считать reported outputs проверенными, пока файлы не обнаружены и не сверены.

Связанная бизнес/операционная документация ведётся отдельно в `convergentaru/pc-rescue-platform`. В этом AI-репозитории фиксируется только связанный контекст и ссылки, чтобы не дублировать Sysvera master dossier. Локальный репозиторий `acer-rescue-usb` ранее не имел подтверждённого GitHub remote; не приписывать ему remote без проверки.

## 10. Неизменяемые рабочие правила

- GitHub-first память: существенные исходные условия, решения, тесты, ошибки, ограничения и следующий шаг документировать в репозитории соответствующего проекта.
- Не создавать дублирующие репозитории/базы знаний, если уже есть подходящий проект.
- Сначала read-only evidence; затем план; изменение только после явного согласования, когда оно может затронуть данные, конфигурацию, модель, сервис или USB.
- Не переустанавливать Ubuntu, не переключать модель и не переписывать рабочие конфиги «для чистоты».
- Сохранять известные рабочие baseline и исходные ISO.
- Не публиковать API keys, passwords, tokens, `.env`, приватные пользовательские данные.
- Не использовать старые PID/порты как текущие.
- Не путать процесс агента, Gateway, API wrapper, inference server и загруженную модель.
- Не объявлять тест успешным только потому, что процесс запущен или порт открыт: нужен реальный запрос/ответ через нужный маршрут.
- Перед техническим решением проверять официальную документацию, исходный код/Issues/PR и независимые профильные источники; для восстановления после reboot сначала снять локальный read-only state.

## 11. Что остаётся неизвестным

1. Какое точное состояние процессов/сервисов после последнего загрязнённого запуска и после reboot.
2. Появилась ли в последнем эксперименте вторая копия модели или только второй сервер/router.
3. Был ли реальный kernel OOM kill в ночном инциденте.
4. Какова точная причина отказа загрузки производного SystemRescue ISO на HP.
5. Какие именно существующие launch scripts и desktop launchers сейчас корректны.
6. Какие outputs перевода SystemRescue сохранились и не перезаписали ли они оригиналы.
7. Поддерживает ли установленная версия Unsloth нужный вариант повторного запуска Hermes без создания второго inference server — до проверки считать UNKNOWN.

## 12. Порядок продолжения

**Первый шаг после reboot:** получить read-only snapshot из раздела 6 и сохранить полный вывод локально. Не запускать агенты до этого.

**Второй шаг:** сопоставить фактический snapshot с целевой архитектурой из раздела 2. Если есть расхождения — только исследовать владельца процесса и его назначение; ничего не останавливать наугад.

**Третий шаг:** восстановить один Unsloth server и один слот, используя существующий управляющий слой `unsloth`, затем проверить API реальным запросом.

**Четвёртый шаг:** проверить по одному Hermes и Claude Code как клиентов общего endpoint. Не делать второй сервер.

**Пятый шаг:** отдельно вести расследование SystemRescue USB по read-only evidence, не совмещать с runtime экспериментов.

## 13. Источники внутри GitHub

- [CURRENT_STATE.md](../../../CURRENT_STATE.md) — текущая и историческая фиксация runtime.
- [KNOWN_GOOD_CONFIGS.md](../../../KNOWN_GOOD_CONFIGS.md) — проверенные команды и конфигурации.
- [EXPERIMENT_LOG.md](../../../EXPERIMENT_LOG.md) — последовательность экспериментов и ошибок.
- [DECISIONS.md](../../../DECISIONS.md) — принятые архитектурные решения.
- [SESSION_BOOTSTRAP.md](../../../SESSION_BOOTSTRAP.md) — краткая точка входа в контекст.
- [SystemRescue translation/context audit in PC Rescue Platform](https://github.com/convergentaru/pc-rescue-platform/blob/main/docs/SYSTEMRESCUE-TRANSLATION-RECOVERY-AND-CONTEXT-AUDIT-2026-10-31.md) — отдельный аудит перевода и сжатия контекста.


---

## User-requested separate post-reboot work orders — 2026-11-01

The next session must also read [POST-REBOOT-WORK-ORDERS.md](POST-REBOOT-WORK-ORDERS.md). It contains:
- the full copy/paste Hermes prompt to finish the Russian SystemRescue 13.02 documentation translation;
- the separate Claude Code engineering assignment for the SystemRescue rescue USB, based on the user's observed difference in task performance;
- the staged Paperclip plan for a one-person AI-operated company;
- the resource-safe sequential activation rule: one heavy agent task at a time on the current single Unsloth inference slot.

The user has not yet sent the referenced video. Its contents are UNKNOWN until received and reviewed.
