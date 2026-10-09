#!/usr/bin/env bash
# Sequential GGUF downloader for llama.cpp; resumable; skips valid files.
set -uo pipefail

MODELS_ROOT="$HOME/models"
ROOT="$MODELS_ROOT"
VENV="$HOME/.venvs/hf-model-downloader"
HF="$VENV/bin/hf"
LOCK="$HOME/.model-collection-download.lock"
LOG="$HOME/model-downloads-validated.log"
PIDFILE="$HOME/model-downloads-validated.pid"
STATUS="$ROOT/MODEL-COLLECTION-DOWNLOAD-STATUS.txt"
SCRIPT_PATH="$(readlink -f "$0")"

if [[ "${1:-}" != "--worker" ]]; then
    mkdir -p "$ROOT" "$HOME/.venvs"
    if ! flock -n "$LOCK" -c true; then
        echo "Предыдущий загрузчик уже работает; второй не запускаю."
        tail -n 25 "$HOME/model-downloads.log" 2>/dev/null || true
        exit 1
    fi
    command -v systemd-inhibit >/dev/null 2>&1 || {
        echo "Не найден systemd-inhibit; загрузка не запущена."
        exit 1
    }
    if ! python3 -c 'import venv' >/dev/null 2>&1; then
        echo "Устанавливаю python3-venv (может потребоваться пароль sudo)..."
        sudo apt-get update && sudo apt-get install -y python3-venv || exit 1
    fi
    [[ -x "$HF" ]] || python3 -m venv "$VENV" || exit 1
    echo "Проверяю Hugging Face downloader..."
    "$VENV/bin/python" -m pip install --upgrade "huggingface_hub[hf_xet]" || exit 1
    "$HF" --help >/dev/null 2>&1 || exit 1

    echo "Подготовка завершена. Запускаю загрузку в фоне."
    echo "Каталог: $ROOT"
    echo "Журнал: $LOG"
    nohup systemd-inhibit \
        --what=sleep \
        --who="Local GGUF model collection" \
        --why="Sequential model downloads" \
        --mode=block \
        bash "$SCRIPT_PATH" --worker \
        </dev/null >/dev/null 2>&1 &
    echo $! > "$PIDFILE"
    sleep 3
    tail -n 22 "$LOG" 2>/dev/null || echo "Загрузчик стартует; журнал появится через несколько секунд."
    exit 0
fi

exec 9>"$LOCK"
if ! flock -n 9; then
    echo "Другой загрузчик держит блокировку. Выход." >> "$LOG"
    exit 1
fi
mkdir -p "$ROOT"
exec >> "$LOG" 2>&1
export HF_HUB_DISABLE_TELEMETRY=1

echo
echo "============================================================"
echo "Последовательная коллекция GGUF — $(date '+%F %T')"
echo "Цель: $ROOT"
echo "============================================================"

LABELS=(
  "Qwen3.5-9B Q4_K_M"
  "Qwen3.5-9B vision projector F16"
  "Ministral 3 8B Instruct Q4_K_M"
  "Gemma 4 E4B Instruct Q4_K_M"
  "Gemma 4 E4B vision projector F16"
  "QVikhr-3-4B-Instruction Q4_K_M"
  "Saiga-YandexGPT-8B Q4_K_M"
  "DeepSeek-R1-Distill-Qwen-14B Q4_K_M"
  "GLM-4.7-Flash IQ2_XXS"
  "Gemma 4 12B Instruct Q4_K_M (night test)"
  "Gemma 4 12B vision projector F16"
  "GPT-OSS-20B MXFP4 (night test)"
)
REPOS=(
  "unsloth/Qwen3.5-9B-GGUF"
  "unsloth/Qwen3.5-9B-GGUF"
  "mistralai/Ministral-3-8B-Instruct-2512-GGUF"
  "mradermacher/gemma-4-E4B-it-GGUF"
  "mradermacher/gemma-4-E4B-it-GGUF"
  "Vikhrmodels/QVikhr-3-4B-Instruction-GGUF"
  "IlyaGusev/saiga_yandexgpt_8b_gguf"
  "bartowski/DeepSeek-R1-Distill-Qwen-14B-GGUF"
  "Mungert/GLM-4.7-Flash-GGUF"
  "mradermacher/gemma-4-12B-it-GGUF"
  "mradermacher/gemma-4-12B-it-GGUF"
  "ggml-org/gpt-oss-20b-GGUF"
)
FILES=(
  "Qwen3.5-9B-Q4_K_M.gguf"
  "mmproj-F16.gguf"
  "Ministral-3-8B-Instruct-2512-Q4_K_M.gguf"
  "gemma-4-E4B-it.Q4_K_M.gguf"
  "gemma-4-E4B-it.mmproj-f16.gguf"
  "QVikhr-3-4B-Instruction-Q4_K_M.gguf"
  "saiga_yandexgpt_8b.Q4_K_M.gguf"
  "DeepSeek-R1-Distill-Qwen-14B-Q4_K_M.gguf"
  "GLM-4.7-Flash-iq2_xxs.gguf"
  "gemma-4-12B-it.Q4_K_M.gguf"
  "gemma-4-12B-it.mmproj-f16.gguf"
  "gpt-oss-20b-MXFP4.gguf"
)
FOLDERS=(
  "qwen3.5-9b" "qwen3.5-9b" "ministral-3-8b"
  "gemma-4-e4b" "gemma-4-e4b" "qvikhr-3-4b"
  "saiga-yandexgpt-8b" "deepseek-r1-14b" "glm-4.7-flash"
  "gemma-4-12b" "gemma-4-12b" "gpt-oss-20b"
)
MIN_BYTES=(
  5000000000 800000000 4800000000 5000000000
  700000000 2300000000 4600000000 8400000000
  9000000000 7000000000 100000000 11000000000
)
EXPECTED_BYTES=(
  5680000000 920000000 5200000000 5340000000
  1100000000 2500000000 4930000000 8990000000
  9670000000 7380000000 122000000 12100000000
)

find_existing_elsewhere() {
    local filename="$1" min_bytes="$2" exclude_target="$3" min_mib
    min_mib=$((min_bytes / 1048576))
    find "$MODELS_ROOT" \
        -path "$MODELS_ROOT/model-collection" -prune -o \
        -path "$exclude_target" -prune -o \
        -type f -name "$filename" -size "+${min_mib}M" -print -quit 2>/dev/null
}
is_valid() {
    local path="$1" min_bytes="$2" size
    [[ -f "$path" ]] || return 1
    size="$(stat -c%s "$path" 2>/dev/null || echo 0)"
    (( size >= min_bytes ))
}

NEEDED=0
for i in "${!FILES[@]}"; do
    target="$ROOT/${FOLDERS[$i]}/${FILES[$i]}"
    if is_valid "$target" "${MIN_BYTES[$i]}"; then continue; fi
    existing="$(find_existing_elsewhere "${FILES[$i]}" "${MIN_BYTES[$i]}" "$target")"
    if [[ -n "$existing" ]]; then continue; fi
    current=0
    [[ -f "$target" ]] && current="$(stat -c%s "$target" 2>/dev/null || echo 0)"
    remaining=$((EXPECTED_BYTES[$i] - current))
    (( remaining > 0 )) && NEEDED=$((NEEDED + remaining))
done
AVAILABLE="$(df -PB1 "$ROOT" | awk 'NR==2 {print $4}')"
RESERVE=$((8 * 1024 * 1024 * 1024))
if [[ -z "${AVAILABLE:-}" ]] || (( AVAILABLE < NEEDED + RESERVE )); then
    echo "ОШИБКА: мало свободного места."
    echo "Остаток загрузок около $((NEEDED / 1000000000)) GB; дополнительно нужен резерв 8 GiB."
    df -h "$ROOT"
    exit 1
fi
echo "Примерно осталось скачать: $((NEEDED / 1000000000)) GB."
echo "Свободное место: $((AVAILABLE / 1000000000)) GB."

FAILED=0
SUCCESS=0
SKIPPED=0
TOTAL="${#FILES[@]}"

download_one() {
    local i="$1"
    local label="${LABELS[$i]}" repo="${REPOS[$i]}"
    local filename="${FILES[$i]}" dest="$ROOT/${FOLDERS[$i]}"
    local target="$dest/$filename" min_bytes="${MIN_BYTES[$i]}"
    local existing attempt size
    mkdir -p "$dest"

    if is_valid "$target" "$min_bytes"; then
        echo "SKIP: $label — уже скачано"
        SKIPPED=$((SKIPPED + 1))
        return 0
    fi
    existing="$(find_existing_elsewhere "$filename" "$min_bytes" "$target")"
    if [[ -n "$existing" ]]; then
        rm -f "$target"
        ln -s "$existing" "$target"
        echo "SKIP/LINK: $label — использую имеющийся файл: $existing"
        SKIPPED=$((SKIPPED + 1))
        return 0
    fi

    echo
    echo "============================================================"
    echo "[$((i+1))/$TOTAL] СКАЧИВАЮ: $label"
    echo "Repo: $repo"
    echo "File: $filename"
    echo "Start: $(date '+%F %T')"
    echo "============================================================"

    for attempt in 1 2 3; do
        echo "Попытка $attempt/3; повторная загрузка использует механизм возобновления HF."
        if "$HF" download "$repo" "$filename" --local-dir "$dest"; then
            if is_valid "$target" "$min_bytes"; then
                size="$(stat -c%s "$target")"
                echo "ГОТОВО: $label — $((size / 1000000)) MB"
                SUCCESS=$((SUCCESS + 1))
                return 0
            fi
            echo "Файл отсутствует или меньше ожидаемого размера."
        else
            echo "Команда hf download завершилась ошибкой."
        fi
        (( attempt < 3 )) && sleep 15
    done
    echo "ОШИБКА: $label; пропускаю к следующему файлу."
    FAILED=$((FAILED + 1))
    return 0
}

for i in "${!FILES[@]}"; do
    download_one "$i"
done

{
    echo "Коллекция GGUF — итог"
    echo "Завершено: $(date '+%F %T')"
    echo "Успешно загружено в этом запуске: $SUCCESS"
    echo "Пропущено/переиспользовано: $SKIPPED"
    echo "Ошибок: $FAILED"
    echo
    echo "[Файлы GGUF]"
    find "$ROOT" -type f -name '*.gguf' -printf '%P | %s bytes\n' 2>/dev/null | sort
    echo
    echo "[Ссылки на GGUF]"
    find "$ROOT" -type l -name '*.gguf' -printf '%P -> %l\n' 2>/dev/null | sort
} > "$STATUS"

echo
echo "ОЧЕРЕДЬ ЗАВЕРШЕНА: $(date '+%F %T')"
echo "Успешно: $SUCCESS; пропущено/переиспользовано: $SKIPPED; ошибок: $FAILED"
echo "Отчёт: $STATUS"
echo "Журнал: $LOG"
