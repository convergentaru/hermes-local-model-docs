# Установка локальных AI-skills в Hermes

Навыки находятся в этом репозитории и устанавливаются в пользовательский каталог Hermes. Отдельно ставить их после каждой перезагрузки не нужно: после установки они остаются в `~/.hermes/skills/` и доступны в новых сессиях. При новой установке Hermes их нужно установить заново.

## Навыки

- [local-ai-stack-diagnostics](https://github.com/convergentaru/hermes-local-model-docs/blob/main/skills/local-ai-stack-diagnostics/SKILL.md) — диагностика портов, провайдеров и маршрута модели; не исправляет конфиг на основании одного различия портов.
- [unsloth-hermes-connect](https://github.com/convergentaru/hermes-local-model-docs/blob/main/skills/unsloth-hermes-connect/SKILL.md) — подключение запущенной модели Unsloth к визуальному Hermes Desktop.
- [hermes-voice-setup](https://github.com/convergentaru/hermes-local-model-docs/blob/main/skills/hermes-voice-setup/SKILL.md) — последовательная настройка и отдельная проверка STT, LLM и TTS.

## Установка

### Самый простой вариант — одна команда из GitHub

В обычном терминале Ubuntu (после установки Hermes) выполните:

~~~bash
curl -fsSL https://raw.githubusercontent.com/convergentaru/hermes-local-model-docs/main/scripts/install-hermes-local-ai-skills.sh -o /tmp/install-hermes-local-ai-skills.sh && bash /tmp/install-hermes-local-ai-skills.sh
~~~

Скрипт добавляет репозиторий как Hermes skills tap и устанавливает четыре навыка: главный `robot-factory-setup`, диагностику, подключение Unsloth и настройку голоса. Уже видимые навыки не перезаписываются. Установщик не редактирует модельные и голосовые настройки, не скачивает модели и не выводит API-ключи.

### Установить репозиторий как источник вручную

~~~bash
hermes skills tap add convergentaru/hermes-local-model-docs
hermes skills install convergentaru/hermes-local-model-docs/robot-factory-setup
hermes skills install convergentaru/hermes-local-model-docs/local-ai-stack-diagnostics
hermes skills install convergentaru/hermes-local-model-docs/unsloth-hermes-connect
hermes skills install convergentaru/hermes-local-model-docs/hermes-voice-setup
~~~

### Установить отдельные skills по прямым URL

~~~bash
hermes skills install https://raw.githubusercontent.com/convergentaru/hermes-local-model-docs/main/skills/robot-factory-setup/SKILL.md --name robot-factory-setup
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
