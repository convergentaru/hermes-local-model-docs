# Experiment Log — ChatGPT Bridge

Формат каждой записи:
- Дата / время:
- Цель:
- Исходное состояние:
- Действия:
- Ожидаемый результат:
- Фактический результат:
- Логи / evidence (без секретов):
- Вывод:
- Следующий шаг:

---

## 2026-11-11 — первичный GitHub README review

**Цель:** определить роль репозитория lesterppo/hermes-chatgpt-web-cli и выбрать первичный архитектурный маршрут.

**Проверено:** публичный README и структура репозитория; README AI Free; README lesterppo/hermes-web-clis.

**Результат:**
- `hermes-chatgpt-web-cli` — небольшой специализированный Playwright CLI, полезный как технический образец.
- `hermes-web-clis` — более широкий проект; README описывает headed Chromium/CDP для ChatGPT.
- AI Free уже декларирует ChatGPT provider и OpenAI-compatible local API.

**Решение:** первым проверять AI Free → API → Hermes. Сторонние CLI/CDP решения оставить сравнительными вариантами.

**Ограничение:** локальная машина пока не проверялась; фактическая работоспособность не подтверждена.
