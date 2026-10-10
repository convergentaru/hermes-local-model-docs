# Установка локальных AI-skills в Hermes

Навыки находятся в этом репозитории и устанавливаются в пользовательский каталог Hermes. Отдельно ставить их после каждой перезагрузки не нужно: после установки они остаются в `~/.hermes/skills/` и доступны в новых сессиях. При новой установке Hermes их нужно установить заново.

## Навыки

- [local-ai-stack-diagnostics](https://github.com/convergentaru/hermes-local-model-docs/blob/main/skills/local-ai-stack-diagnostics/SKILL.md) — диагностика портов, провайдеров и маршрута модели; не исправляет конфиг на основании одного различия портов.
- [unsloth-hermes-connect](https://github.com/convergentaru/hermes-local-model-docs/blob/main/skills/unsloth-hermes-connect/SKILL.md) — подключение запущенной модели Unsloth к визуальному Hermes Desktop.
- [hermes-voice-setup](https://github.com/convergentaru/hermes-local-model-docs/blob/main/skills/hermes-voice-setup/SKILL.md) — последовательная настройка и отдельная проверка STT, LLM и TTS.

## Установка

### Вариант A — установить одним скриптом из локальной копии репозитория

Если репозиторий уже клонирован, из его корня выполните:

~~~bash
bash scripts/install-hermes-local-ai-skills.sh
~~~

Скрипт проверяет CLI Hermes, пропускает навыки, которые уже видны в списке, и устанавливает отсутствующие из raw-файлов GitHub.

### Вариант B — установить отдельными командами

~~~bash
hermes skills install https://raw.githubusercontent.com/convergentaru/hermes-local-model-docs/main/skills/local-ai-stack-diagnostics/SKILL.md --name local-ai-stack-diagnostics
hermes skills install https://raw.githubusercontent.com/convergentaru/hermes-local-model-docs/main/skills/unsloth-hermes-connect/SKILL.md --name unsloth-hermes-connect
hermes skills install https://raw.githubusercontent.com/convergentaru/hermes-local-model-docs/main/skills/hermes-voice-setup/SKILL.md --name hermes-voice-setup
~~~

Hermes официально поддерживает установку одного файла SKILL.md по HTTPS URL. Эти три навыка самодостаточны и не требуют вспомогательных файлов.

## Проверка

~~~bash
hermes skills list | grep -E 'local-ai-stack-diagnostics|unsloth-hermes-connect|hermes-voice-setup'
~~~

Установленные навыки становятся slash-командами. Примеры вызова в Hermes:

~~~text
/local-ai-stack-diagnostics
/unsloth-hermes-connect
/hermes-voice-setup
~~~

Навыки загружаются в контекст новой сессии. После установки начните новую сессию либо выполните `/reset`, если команда поддерживается текущей версией.

## Безопасное обновление

Скрипт установки намеренно не перезаписывает уже установленные навыки. Перед обновлением сохраните текущий каталог навыка и только затем переустановите его. Не используйте `rm -rf ~/.hermes/skills`: там могут находиться другие важные навыки.

## Важное ограничение

Skill — это повторяемая процедура, а не привилегированный установщик операционной системы. Он может проверять окружение и запускать разрешённые команды, но не может гарантированно кликать по любому элементу графического интерфейса. UI-шаги, такие как выбор голоса или модели, могут требовать участия пользователя. Навыки не содержат ключей API или секретов.
