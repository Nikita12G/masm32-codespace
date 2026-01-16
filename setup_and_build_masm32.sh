#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WINEPREFIX="${HOME}/.wine_masm32"
MASM_ZIP_URL="https://masm32.com/masmdl/masm32v11r.zip"
TMPDIR="${HOME}/masm32_setup"

echo "Этот скрипт установит Wine (через apt), распакует MASM32 в Wine C:\\ и запустит build.bat."
echo "Требуются sudo для установки пакетов apt. Если вы в окружении без apt — выйдите."

if ! command -v apt-get >/dev/null 2>&1; then
  echo "apt-get не найден. Запустите вручную на Debian/Ubuntu-хосте или выполните инструкции вручную." >&2
  exit 1
fi

echo "Установка зависимостей (потребуется sudo)..."
sudo dpkg --add-architecture i386 || true
sudo apt-get update -y
sudo apt-get install -y wine64 wine32 p7zip-full unzip wget cabextract || true

export WINEPREFIX="$WINEPREFIX"
export WINEARCH=win32
mkdir -p "$WINEPREFIX/drive_c"

echo "Инициализация Wine-префикса..."
wineboot -u || true

mkdir -p "$TMPDIR"
cd "$TMPDIR"

if [ ! -f masm32.zip ]; then
  echo "Скачиваю MASM32..."
  wget -O masm32.zip "$MASM_ZIP_URL" || {
    echo "Не удалось скачать MASM32. Проверьте сеть или URL: $MASM_ZIP_URL" >&2
    exit 1
  }
fi

echo "Распаковка MASM32 в Wine C:\\..."
7z x masm32.zip -o"$WINEPREFIX/drive_c/" >/dev/null 2>&1 || unzip -o masm32.zip -d "$WINEPREFIX/drive_c/"

if [ ! -d "$WINEPREFIX/drive_c/masm32" ]; then
  echo "Папка masm32 не найдена в Wine C:\\ — возможно, распаковка не удалась." >&2
  ls -la "$WINEPREFIX/drive_c/" || true
  exit 1
fi

echo "Копирую исходники и скрипт сборки в C:\\masm32..."
cp -v "$SCRIPT_DIR/main.asm" "$WINEPREFIX/drive_c/masm32/" || true
cp -v "$SCRIPT_DIR/build.bat" "$WINEPREFIX/drive_c/masm32/" || true

echo "Переход в C:\\masm32 и запуск сборки под Wine..."
cd "$WINEPREFIX/drive_c/masm32"
wine cmd /c build.bat || {
  echo "Сборка под Wine вернула ошибку. Посмотрите вывод выше." >&2
}

if [ -f main.exe ]; then
  OUTDIR="$SCRIPT_DIR/build_output"
  mkdir -p "$OUTDIR"
  cp -v main.exe "$OUTDIR/" || true
  echo "Сборка успешна — main.exe скопирован в: $OUTDIR/main.exe"
else
  echo "main.exe не найден — сборка не удалась." >&2
fi

echo "Готово. Проверьте $OUTDIR или логи Wine для диагностики." 
