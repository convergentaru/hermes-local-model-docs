# Paperclip + Hermes Local: подключение локального агента

Дата фиксации: 2026-11-17  
Статус: **IN PROGRESS** — адаптер Hermes выбран в UI; сквозной запуск задачи ещё не проверен.

## 1. Исходная статья

**John Cook — “Wire Hermes Into Paperclip with the hermes_local Adapter”**, 21 July 2026.

Источник: https://youcanbuildthings.substack.com/p/wire-hermes-into-paperclip-with-the

Статья описывает именно локальный адаптер `hermes_local`: Paperclip запускает локальный Hermes CLI как worker при heartbeat, передаёт ему контекст задачи и переменные доступа к Paperclip, получает результат и usage обратно.

Не копируем статью целиком; ниже — краткая выжимка с привязкой к нашей версии и локальной конфигурации.

## 2. Как устроена связка

- **Paperclip** — control plane: компания, роли, задачи/issues, назначения, heartbeats, approvals, история и учёт запусков.
- **Hermes Agent** — локальный runtime: получает задачу, использует свои tools, skills и память, обращается к настроенному провайдеру модели.
- **`hermes_local`** — встроенный адаптер-мост: запускает Hermes CLI как дочерний процесс для каждого запуска/heartbeat и связывает его с задачей Paperclip.

Упрощённый цикл:

1. В Paperclip создаётся задача и назначается агенту Hermes.
2. Paperclip запускает heartbeat.
3. Адаптер вызывает локальный Hermes CLI в non-interactive режиме.
4. Hermes читает задачу и использует модель из своей конфигурации (если адаптеру не задано явное переопределение).
5. Hermes выполняет разрешённые инструменты и взаимодействует с Paperclip API через runtime-переменные.
6. Адаптер собирает вывод и usage; Paperclip сохраняет результат и состояние задачи.

Это не то же самое, что Hermes Gateway: `hermes_local` запускает CLI локально; `hermes_gateway` подключается к уже работающему Hermes API server по HTTP/SSE.

## 3. Конфигурация из статьи

В статье приведён пример формы адаптера:

```json
{
  "name": "Hermes Engineer",
  "adapterType": "hermes_local",
  "adapterConfig": {
    "model": "anthropic/claude-sonnet-4",
    "maxIterations": 50,
    "timeoutSec": 300,
    "persistSession": true,
    "enabledToolsets": ["terminal", "file", "web"]
  }
}
```

Это **пример автора**, а не конфигурация для копирования в нашу систему. В нём указана облачная модель Anthropic; для нашей установки её использовать нельзя.

В статье также приведены доступные toolsets: `terminal`, `file`, `web`, `browser`, `code_execution`, `vision`, `mcp`, `creative`, `productivity`. Набор инструментов следует ограничивать ролью агента.

## 4. Важное замечание о persistSession и issue #1160

Автор статьи от 2026-07-21 рекомендует временно выставлять `persistSession: false` из-за открытой на момент публикации проблемы Paperclip #1160: некорректный session ID мог сохраняться и затем передаваться Hermes как `--resume`, из-за чего следующие heartbeats быстро завершались с `Session not found`.

Issue: https://github.com/paperclipai/paperclip/issues/1160

Однако README адаптера в нашем Paperclip checkout описывает уже наличие **session codec** для структурированной проверки и миграции состояния сессии; в таблице настроек `persistSession` имеет default `true`. Поэтому рекомендация автора статьи не переносится автоматически на установленную версию. Для первого smoke test нужно проверить фактическое поведение сессий и логи; если появится ошибка `Session not found`/повторное использование некорректного ID, отдельно проверить вариант `persistSession: false`.

Не удалять и не пересоздавать агента только на основании статьи.

## 5. Что подтверждено на этой Ubuntu (2026-11-17)

- Paperclip локально доступен на `http://127.0.0.1:3100`.
- Версия Paperclip: `2026.1106.0`.
- Компания: `Acer Rescue Lab`.
- Hermes CLI: `/home/oleg/.local/bin/hermes`.
- Hermes version: `0.23.0`.
- `hermes status` показал активную модель `Qwen3.5-9B-Q4_K_M` и provider `custom:unsloth-qwen-160k`.
- В Hermes config присутствуют локальные custom endpoints; среди них `http://127.0.0.1:8888/v1` и `http://127.0.0.1:4317/v1`. Секретные значения в эту документацию не записываются.
- На момент проверки слушали порты 8888 и 4317; порт 18434 не слушал.
- `hermes status` сообщил `Gateway: running`. Это само по себе не доказывает, что включён отдельный Hermes API server для адаптера `hermes_gateway`.

## 6. Текущая настройка в Paperclip UI

Агент: **Acer Rescue Engineer**.

В разделе **Harness / Runtime** выбран вариант **Hermes** (локальный Hermes adapter), а не Hermes Gateway.

На экране были видны значения:
- Provider: `Auto`
- Model: `Default`
- Thinking effort: `Auto`

Изменения сохранены кнопкой **Save changes**. На этом этапе агент не запускался.

По README адаптера:
- `hermes_local` запускает локальный Hermes CLI;
- `hermesCommand` позволяет задать абсолютный путь к CLI, если Paperclip не видит его через PATH;
- `model` — необязательное для нашего auto-detection поле только если адаптер корректно определяет модель из `~/.hermes/config.yaml`; проверить фактическое значение в UI/логах запуска;
- `provider` может определяться автоматически;
- `timeoutSec`, `maxIterations`, `persistSession`, `enabledToolsets` и `env` управляют выполнением и инструментами.

**Важно:** в README адаптера таблица перечисляет конкретные inference provider IDs. Наш активный Hermes provider — `custom:unsloth-qwen-160k`. Не считать совместимость custom provider доказанной только по тому, что Hermes CLI отдельно отвечает Qwen. Нужно провести smoke test через Paperclip и убедиться по фактическому логу, что ответ пришёл от нужной локальной модели, а не от облачного fallback.

## 7. Практический порядок подключения и проверки

1. В Paperclip открыть компанию → Agents → нужный агент → Harness / Runtime.
2. Выбрать **Hermes**, не Hermes Gateway.
3. Оставить Provider = Auto и Model = Default на первом тесте, если UI не требует иного; не вводить Anthropic/OpenAI/OpenRouter model IDs.
4. Если запуск выдаёт `hermes: command not found`, указать `hermesCommand` абсолютным путём: `/home/oleg/.local/bin/hermes`.
5. Сохранить настройки.
6. Создать одну безвредную тестовую задачу, назначить её только Hermes и выполнить один heartbeat.
7. Проверить логи: адаптер действительно запустил Hermes CLI; Hermes вызвал ожидаемый local provider/model; задача и результат вернулись в Paperclip; нет cloud fallback, ошибок авторизации или session ID.
8. Проверить второй heartbeat и возобновление сессии. Только после этого включать длительные/периодические задачи.
9. Для первой задачи не давать право изменять систему, писать на физический USB, удалять файлы или отправлять внешние сообщения.

## 8. Второй агент и мультиагентная компания

Статья перечисляет `opencode_local` среди встроенных Paperclip adapters. Это отдельный runtime и отдельный агент, а не «вторая модель внутри Hermes».

План ролей для Acer Rescue Lab:
- **Hermes — координатор / исследователь:** анализ задачи, план, проверка результата, отчёт.
- **OpenCode — инженер-исполнитель:** конкретные изменения в репозитории `acer-rescue-usb`, сборка и тесты по утверждённому заданию.

Текущий локальный статус OpenCode на 2026-11-17: команда находится в `/home/oleg/node_modules/.bin/opencode`, но `opencode --version` завершился сообщением, что postinstall script пакета `opencode-ai` не был выполнен. Поэтому OpenCode пока **не готов к запуску** и второго агента создавать рано.

После восстановления OpenCode нужно отдельно проверить:
- локальный CLI запускается без ошибок;
- выбранный provider/model доступен локально;
- нет незапланированного cloud fallback;
- Paperclip adapter `opencode_local` запускает именно этот CLI;
- агент выполняет безопасную тестовую задачу.

## 9. Ограничения и критерий готовности

Пока не доказано:
- что Paperclip heartbeat запускает Hermes в нашей конкретной конфигурации;
- что Hermes через Paperclip использует именно локальный Qwen provider;
- что сессия корректно продолжается на следующем heartbeat;
- что OpenCode исправлен и подключён;
- что два агента реально передают друг другу работу через задачи/назначения Paperclip.

**Готово** можно объявить только после фактического теста: одна задача назначена Hermes, Hermes выполнил её через локальный Qwen, Paperclip сохранил run и результат. Для мультиагентного статуса дополнительно требуется успешный отдельный run OpenCode и подтверждённая передача результата между агентами.

## 10. Источники

1. John Cook, “Wire Hermes Into Paperclip with the hermes_local Adapter” (2026-07-21): https://youcanbuildthings.substack.com/p/wire-hermes-into-paperclip-with-the
2. Paperclip Hermes adapter README (наш checkout): https://github.com/convergentaru/paperclip/blob/master/packages/adapters/hermes/README.md
3. Paperclip issue #1160: https://github.com/paperclipai/paperclip/issues/1160
4. Paperclip repository: https://github.com/convergentaru/paperclip

---
История/примечания: этот документ фиксирует статью и фактическое состояние нашей установки на 2026-11-17. При изменении Paperclip, Hermes, Unsloth или локального provider обновлять проверенные факты, не перенося автоматически советы автора на новые версии.
