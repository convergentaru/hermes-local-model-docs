# Установка локальных AI-skills в Hermes

Навыки находятся в GitHub-репозитории `convergentaru/hermes-local-model-docs`. Скрипт устанавливает навыки в локальный Hermes; обновление GitHub само по себе не меняет уже установленный экземпляр на компьютере.

## Навыки

- [robot-factory-setup](https://github.com/convergentaru/hermes-local-model-docs/blob/main/skills/robot-factory-setup/SKILL.md) — основной маршрут проверки и настройки.
- [robot-factory-agent-company](https://github.com/convergentaru/hermes-local-model-docs/blob/main/skills/robot-factory-agent-company/SKILL.md) — роли директора, исследователя, исполнителя и аудитора.
- [screenpipe-hermes-memory](https://github.com/convergentaru/hermes-local-model-docs/blob/main/skills/screenpipe-hermes-memory/SKILL.md) — локальная экранная память Screenpipe через MCP с настройками приватности.
- [local-ai-stack-diagnostics](https://github.com/convergentaru/hermes-local-model-docs/blob/main/skills/local-ai-stack-diagnostics/SKILL.md) — диагностика маршрутов модели и портов.
- [unsloth-hermes-connect](https://github.com/convergentaru/hermes-local-model-docs/blob/main/skills/unsloth-hermes-connect/SKILL.md) — подключение загруженной модели Unsloth.
- [hermes-voice-setup](https://github.com/convergentaru/hermes-local-model-docs/blob/main/skills/hermes-voice-setup/SKILL.md) — отдельная настройка и проверка STT, LLM и TTS.

## Установка одним скриптом

В обычном терминале Ubuntu можно выполнить:

~~~bash
curl -fsSL https://raw.githubusercontent.com/convergentaru/hermes-local-model-docs/main/scripts/install-hermes-local-ai-skills.sh -o /tmp/install-hermes-local-ai-skills.sh && bash /tmp/install-hermes-local-ai-skills.sh
~~~

Установщик добавляет репозиторий как Hermes skills tap и устанавливает шесть навыков. Он не устанавливает сам Hermes, не загружает веса моделей и не переписывает конфигурацию провайдера или голоса. Уже видимые навыки скрипт пропускает; обновление существующих навыков выполняется отдельно.

## Установка вручную

~~~bash
hermes skills tap add convergentaru/hermes-local-model-docs
hermes skills install convergentaru/hermes-local-model-docs/robot-factory-setup
hermes skills install convergentaru/hermes-local-model-docs/robot-factory-agent-company
hermes skills install convergentaru/hermes-local-model-docs/screenpipe-hermes-memory
hermes skills install convergentaru/hermes-local-model-docs/local-ai-stack-diagnostics
hermes skills install convergentaru/hermes-local-model-docs/unsloth-hermes-connect
hermes skills install convergentaru/hermes-local-model-docs/hermes-voice-setup
~~~

## Проверка

~~~bash
hermes skills list | grep -E 'robot-factory-setup|robot-factory-agent-company|screenpipe-hermes-memory|local-ai-stack-diagnostics|unsloth-hermes-connect|hermes-voice-setup'
~~~

В новой сессии Hermes можно вызывать:
- `/robot-factory-setup`
- `/robot-factory-agent-company`
- `/screenpipe-hermes-memory`
- `/local-ai-stack-diagnostics`
- `/unsloth-hermes-connect`
- `/hermes-voice-setup`

Подробная инструкция по подключению Screenpipe: [Screenpipe + Hermes](https://github.com/convergentaru/hermes-local-model-docs/blob/main/docs/screenpipe/hermes-screenpipe-setup.md).

## Безопасность

Навык — это повторяемая процедура, а не привилегированный системный установщик. Для записи экрана/аудио, изменения системных служб и настройки браузера может потребоваться участие пользователя. Screenpipe сначала настраивать на экранный захват без микрофона, без облачной синхронизации и без автозапуска; постоянную запись включать только после отдельного согласия.
