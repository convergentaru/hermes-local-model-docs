# Architecture — ChatGPT Bridge

## Вариант A (основной кандидат): AI Free как provider adapter

```
[Visible ChatGPT browser session]
             |
             v
[AI Free ChatGPT provider]
             |
             v
[AI Free local OpenAI-compatible API]
             |
             v
[Hermes custom provider]
             |
             v
[Hermes tasks / tools / agent loop]
```

Преимущества:
- один слой browser/session integration;
- AI Free уже присутствует в пользовательской среде;
- Hermes подключается через стандартный OpenAI-compatible интерфейс;
- меньше новых компонентов и отдельных профилей.

Риски:
- API может не полностью отражать все возможности ChatGPT Web;
- сессия может истекать или требовать интерактивной проверки;
- streaming, tool calls, attachments и лимиты нужно тестировать отдельно.

## Вариант B: отдельный Hermes CLI/CDP adapter

```
[Persistent headed Chromium profile]
             |
             v
[Playwright / CDP adapter]
             |
             v
[CLI or Hermes tool wrapper]
             |
             v
[Hermes Agent]
```

Преимущества:
- прямой специализированный интеграционный путь;
- можно исследовать долгоживущий headed browser/CDP;
- потенциально полезен как отдельный инструмент Hermes.

Недостатки:
- второй компонент авторизации и отдельный browser profile;
- отдельные зависимости, процессы и обслуживание;
- DOM automation может ломаться при изменениях веб-интерфейса;
- не следует параллельно запускать конкурирующие браузерные контексты без понимания профилей.

## Принцип выбора

Сначала проверяется вариант A. Вариант B не устанавливается и не запускается, пока не доказано, что AI Free не покрывает требуемый сценарий.

## Границы

- ChatGPT Web automation не эквивалентна официальному OpenAI API.
- Доступность, лимиты, модели и правила использования определяются платформой и аккаунтом.
- Не обещать постоянную доступность или обход Cloudflare.
- Не переносить браузерные clearance/cookie данные между независимыми контекстами.
- Секреты и браузерные профили остаются локально.
