# Как попросить Hermes установить навыки из GitHub и проверить их

Этот файл содержит готовое задание для Hermes Desktop. Сначала изучить и установить навыки; конфигурацию локальной модели не менять.

## Промпт для Hermes

```text
Подключись к публичному GitHub-репозиторию convergentaru/hermes-local-model-docs.

1. Проверь наличие Hermes CLI и версию.
2. Прочитай скрипт установки:
   https://raw.githubusercontent.com/convergentaru/hermes-local-model-docs/main/scripts/install-hermes-local-ai-skills.sh
3. Перед запуском проверь содержимое скрипта. Запусти его через Terminal tool, если оно выглядит соответствующим задаче.
4. Скрипт должен установить эти шесть навыков:
   - robot-factory-setup
   - robot-factory-agent-company
   - screenpipe-hermes-memory
   - local-ai-stack-diagnostics
   - unsloth-hermes-connect
   - hermes-voice-setup
5. Проверь наличие каждого названия через hermes skills list.
6. Если произошла ошибка, не угадывай синтаксис и не переписывай конфигурацию. Изучи hermes skills --help, сообщи точную ошибку и предложи минимальное исправление.
7. Не используй sudo. Не скачивай модели. Не меняй API-ключи, настройки провайдера, адреса API, голос, браузер или ~/.hermes/config.yaml, кроме случаев, отдельно подтверждённых мной.
8. Для запуска основной процедуры в новой сессии используй /robot-factory-setup.
9. Screenpipe пока не устанавливай и не включай запись: отдельное задание — сначала инвентаризация, затем согласование privacy-настроек. Для Screenpipe по умолчанию аудио и облачные функции выключены, автозапуск записи не включать без моего отдельного согласия.

В конце дай краткий отчёт PASS/FAIL по каждому навыку.
```

## Если Hermes не имеет доступа к терминалу

В обычном терминале Ubuntu:

~~~bash
curl -fsSL https://raw.githubusercontent.com/convergentaru/hermes-local-model-docs/main/scripts/install-hermes-local-ai-skills.sh -o /tmp/install-hermes-local-ai-skills.sh && bash /tmp/install-hermes-local-ai-skills.sh
~~~

Затем открой новую сессию Hermes и вызови:

~~~text
/robot-factory-setup
~~~

Установщик предназначен только для навыков. Он не устанавливает сам Hermes, не скачивает модели и не запускает Screenpipe.
