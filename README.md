# Hermes + Unsloth: локальная AI-лаборатория

База знаний по Ubuntu-компьютеру: модели, Unsloth Desktop, собственная CUDA-сборка llama.cpp, Hermes Desktop, голосовой ввод и кодовые агенты.

> Ведём документацию по принципу: проверенные факты отдельно от планов. Не публикуем API-ключи, пароли, токены и содержимое файлов секретов.

## Текущее устройство

- Библиотека моделей: `/home/oleg/models`.
- GUI выбора и запуска моделей: Unsloth Desktop.
- GGUF inference engine: CUDA.
- Custom llama.cpp folder: `/home/oleg/llama.cpp/build-cublas/bin`.
- Основной агент: визуальный Hermes Desktop.
- Проверенная модель через Unsloth: Qwen3.5-4B Q4_K_M, alias `qwen35-4b`.
- Голос: Qwen3-ASR-0.6B распознаёт русскую речь в Unsloth. Прямая интеграция этого ASR с Hermes и TTS ещё не завершены.
- Код: Aider 0.86.2 установлен; Little-coder установлен, но в последнем сеансе не проходил отдельный тест.

## Навигация

## Единая память и текущая работа

- [SESSION_BOOTSTRAP.md](SESSION_BOOTSTRAP.md) — короткая точка восстановления контекста после перерыва.
- [AGENTS.md](AGENTS.md) — инструкции для Hermes, OpenCode и jcode при работе в этом репозитории.
- [Протокол общей памяти ChatGPT ↔ Hermes ↔ GitHub](docs/operations/SHARED-MEMORY-PROTOCOL.md).
- [Текущее состояние локального AI-стека](CURRENT_STATE.md).
- [Проверенные и исторические конфигурации](KNOWN_GOOD_CONFIGS.md).
- [Журнал экспериментов и ошибок](EXPERIMENT_LOG.md).
- [Архитектурные решения](DECISIONS.md).
- [Следующее действие](NEXT_ACTION.md).

### Screenlife — два агента, одна модель

- [Проект SCREENLIFE: два агента, одна модель](docs/screenlife/README.md).
- [Повторный запуск сессии](docs/screenlife/RUNBOOK.md).
- [Команды и конфигурация](docs/screenlife/COMMANDS.md).
- [Производство и съёмка](docs/screenlife/PRODUCTION.md).
- [Сессия 31 октября 2026](docs/screenlife/sessions/2026-10-31/README.md).

### Screenpipe

- [Screenpipe + Hermes: локальная экранная память](docs/screenpipe/hermes-screenpipe-setup.md)
- [Skill Screenpipe для Hermes](skills/screenpipe-hermes-memory/SKILL.md)

### Архитектура

- [Архитектура текущего локального AI-стека](docs/architecture/current-local-ai-stack.md)

### Hermes

- [Project Atlas: аудит проектов, долговременная память и синхронизация](docs/hermes/PROJECT-ATLAS-PROMPT.md).
- [Hermes Desktop: настройки, auxiliary-задачи и голос](docs/hermes/desktop-settings-and-voice.md)
- [Пошаговый чек-лист Hermes Desktop](docs/hermes/desktop-practical-checklist.md)
- [Главный setup-skill Robot Factory OS](skills/robot-factory-setup/SKILL.md)
- [Безопасный запуск Hermes Desktop в каталоге Robot Factory OS](scripts/start-hermes-desktop.sh)
- [Компания агентов: роли, видимый браузер и поиск](docs/robot-factory/agent-company-mvp.md)
- [Skill компании агентов](skills/robot-factory-agent-company/SKILL.md)

### Повторяемая настройка (Hermes Skills)

- [Установка и использование наших skills](docs/skills/install-hermes-skills.md)
- [Готовый промпт для Hermes: установить skills из GitHub и проверить их](docs/hermes/prompt-install-and-test-from-github.md)
- [Единая команда установки из GitHub](scripts/install-hermes-local-ai-skills.sh)
- [Диагностика портов и провайдеров](skills/local-ai-stack-diagnostics/SKILL.md)
- [Подключение Unsloth к Hermes Desktop](skills/unsloth-hermes-connect/SKILL.md)
- [Голосовой ввод и озвучивание](skills/hermes-voice-setup/SKILL.md)

### Unsloth

- [Unsloth Desktop: общая библиотека, CUDA и собственный llama.cpp](docs/unsloth/studio-model-library-and-custom-llama-cpp.md)

### Голос

- [Qwen3-ASR, STT и TTS: текущие результаты и план интеграции](docs/voice/qwen3-asr-and-hermes-voice.md)
- [Первый разговор с Hermes Desktop: текст, микрофон и озвучивание](docs/voice/hermes-desktop-first-voice-test.md)

### Выбор моделей

- [Протокол benchmark моделей и производительности](docs/model-selection/BENCHMARK-PROTOCOL.md) — повторяемые измерения TTFT, prefill/generation, VRAM/RAM, качества tool calling и корректности задач.


- [Кандидаты для обновления модели Hermes + Claude Code](docs/model-selection/2026-10-31-upgrade-candidates.md) — Qwen3.8-27B и ранее использовавшаяся Qwen3.6-35B-A3B; без изменения текущей конфигурации.

### Аудит домашней папки

- [Сравнительный аудит HOME: Hermes vs Claude Code](docs/operations/HOME-DIRECTORY-AUDIT.md) — безопасный read-only протокол, проверка одного серверного слота и перекрёстная проверка отчётов.
- [Длительная работа агентов и Paperclip](docs/operations/LONG-RUNNING-AGENT-WORK-PAPERCLIP.md) — ролевые задания, checkpoints, heartbeats, cross-review и подготовка к ночным задачам.
- [Готовые длинные задания HOME-аудита](docs/operations/HOME-AUDIT-LONG-TASK-PROMPTS.md) — отдельные промпты для Hermes, Claude Code и взаимной проверки.

### Интеграции

- [Hermes ↔ Claude Code: варианты интеграции и решение](docs/integrations/hermes-claude-code.md) — исследование и решение пока не настраивать MCP.

### Кодовые агенты

- [Aider и Little-coder: установка, тесты, ограничения контекста](docs/coding-agents/aider-and-little-coder.md)

### Отчёты экспериментов

- [10 октября 2026: Unsloth + Qwen3.5-4B](docs/experiments/2026-10-10-unsloth-qwen35-4b.md)
- [10 октября 2026: диагностика портов Unsloth и llama-server](docs/experiments/2026-10-10-unsloth-port-routing-diagnosis.md)
- [9–10 октября 2026: Qwen3.6-35B и Aider](docs/experiments/2026-10-10-qwen36-35b-context-and-aider.md)

### Ранее созданные документы

- [Выбор локальной модели для Hermes](hermes-local-model-selection-and-setup.md)
- [Установка Qwen3.6-35B-A3B](qwen36-35b-a3b-ubuntu-install.md)
- [Дорожная карта локальной AI-лаборатории: LEGO/CAD/анализ крыш](local-ai-lab-lego-cad-roof-vision-roadmap.md)
- [Скрипт загрузки коллекции моделей](scripts/download-local-model-collection.sh)
- [Объединение библиотеки моделей и запуск Unsloth](scripts/unify-model-library-and-start-unsloth.sh)

### Диагностика неполадок

- [Восстановление Hermes Desktop после Custom HTTP 401 (Unsloth)](docs/troubleshooting/2026-10-10-hermes-custom-401-unsloth.md)

## Проверенные результаты

- Unsloth Desktop запускает Qwen3.5-4B через пользовательский бинарник llama.cpp; короткий ответ `UNSLOTH_CUDA_TEST_OK` прошёл. UI показал 68.4 tok/s.
- Команда `unsloth start hermes --app` выполнена; визуальный Hermes после подключения успешно ответил контрольной строкой.
- Qwen3-ASR-0.6B хорошо распознаёт русскую речь внутри Unsloth.
- Не завершено: передача аудио из Hermes непосредственно в Qwen3-ASR-0.6B и озвучивание ответов Hermes.
- Не проверено: переключение моделей через GUI во всех сценариях и полная стабильность очень длинного контекста.

## Ссылки

- [Hermes Desktop: подробная настройка](https://habr.com/ru/articles/1044270/)
- [Hermes: оптимизация вспомогательных моделей](https://habr.com/ru/articles/1042860/)
- [Hermes Agent](https://github.com/NousResearch/hermes-agent)
- [Unsloth](https://github.com/unslothai/unsloth)
- [llama.cpp](https://github.com/ggml-org/llama.cpp)
- [Aider](https://aider.chat/)
- [Little-coder](https://github.com/itayinbarr/little-coder)
