# Как попросить Hermes установить навыки из GitHub и проверить их

Этот файл содержит готовое задание для установленного Hermes Desktop. Его нужно вставить **в чат Hermes**, а не выполнять вручную в терминале.

## Промпт для Hermes

```text
Подключись к моему публичному GitHub-репозиторию convergentaru/hermes-local-model-docs и установи оттуда подготовленные навыки Robot Factory OS.

Работай через свой Terminal tool. Выполни задачу по шагам:

1. Проверь `command -v hermes` и `hermes --version`. Если CLI недоступен, остановись и объясни, что именно не найдено.
2. Скачай установщик из моего GitHub в /tmp, сначала просмотри его содержимое, затем запусти:
   https://raw.githubusercontent.com/convergentaru/hermes-local-model-docs/main/scripts/install-hermes-local-ai-skills.sh
3. Установщик должен добавить tap convergentaru/hermes-local-model-docs и установить навыки:
   - robot-factory-setup
   - local-ai-stack-diagnostics
   - unsloth-hermes-connect
   - hermes-voice-setup
4. После установки проверь `hermes skills list` и отдельно проверь, что все четыре имени присутствуют.
5. Если команда установки завершилась ошибкой, НЕ пробуй наугад другие команды и НЕ редактируй конфигурацию. Покажи короткий фрагмент ошибки, выясни поддерживаемый синтаксис через `hermes skills --help` и предложи минимальное исправление.
6. Не используй sudo; не скачивай модели; не меняй настройки провайдера, модели, портов, STT/TTS и не редактируй ~/.hermes/config.yaml. Не печатай секреты и API-ключи.
7. В конце дай отчёт PASS / FAIL по установке каждого навыка и напиши, что для запуска главной процедуры в новой сессии Hermes я должен вызвать:
   /robot-factory-setup

Важно: установка навыков не означает, что голосовая цепочка уже настроена. Отдельно проверим STT → ответ модели → TTS. Не объявляй голос готовым без реальных тестов.
```

## Если Hermes не умеет самостоятельно работать с терминалом

Открой обычный терминал Ubuntu и выполни эту команду. Она сохраняет скрипт в /tmp, затем запускает его:

```bash
curl -fsSL https://raw.githubusercontent.com/convergentaru/hermes-local-model-docs/main/scripts/install-hermes-local-ai-skills.sh -o /tmp/install-hermes-local-ai-skills.sh && bash /tmp/install-hermes-local-ai-skills.sh
```

Затем открой **новую сессию** Hermes Desktop и введи:

```text
/robot-factory-setup
```

Установщик предназначен для установки навыков Hermes. Он не устанавливает сам Hermes, не устанавливает системные пакеты и не меняет настройки выбранной модели или голоса.
