# Испытание 1 — системный аудит Ubuntu 26

Одинаковый read-only prompt был передан Hermes и Claude Code.

## Hermes

См. [полный ответ Hermes](hermes.md).

Основные заявленные результаты: Intel CPU, 4 ядра/потока (точная модель не названа); NVIDIA GeForce RTX 3060, 12 GB; RAM 11 GiB, 7.8 GiB занято и 467 MiB free; Swap 4 GiB, 1.4 GiB использовано; около 1.2 GB свободной VRAM; один llama-server, PID 259764, порт 55831, Qwen3.5-9B-Q4_K_M.

Ограничение: не приведён полный stdout команд.

## Claude Code

См. [ответ Claude Code](claude-code.md).

Видимый статус: `Thought for 37s, ran 9 shell commands`.

Заявлены RAM 11 GiB и 2.1 GiB свободно; Swap 4 GiB и 2.3 GiB свободно; VRAM около 1.2 GiB; один llama-server на 55831; context 160K, parallel 1, Flash Attention ON.

Ответ был частично повреждён форматированием. Claude интерпретировал `--fit-target 548` как 548-token context, что неверно: фактический контекст подтверждён `-c 160000`.

## Сравнение

Hermes — более ясная итоговая таблица. Claude Code — более явный след команд и больше технических параметров, но transcript частично повреждён. RAM нельзя строго сравнить без полного stdout и различения `free` и `available`.
