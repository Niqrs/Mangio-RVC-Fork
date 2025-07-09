#!/bin/bash

echo "=== Скачивание предобученных моделей для Mangio RVC ==="
echo ""

# Функция для скачивания файлов (работает и с wget, и с curl)
download_file() {
    local url=$1
    local output=$2
    
    if command -v wget >/dev/null 2>&1; then
        wget -O "$output" "$url"
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o "$output" "$url"
    else
        echo "Ошибка: Ни wget, ни curl не найдены. Установите один из них."
        exit 1
    fi
}

# Функция для скачивания в директорию
download_to_dir() {
    local url=$1
    local dir=$2
    local filename=$(basename "$url")
    
    if command -v wget >/dev/null 2>&1; then
        wget -P "$dir" "$url"
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o "$dir/$filename" "$url"
    else
        echo "Ошибка: Ни wget, ни curl не найдены. Установите один из них."
        exit 1
    fi
}

# Создание директорий
echo "Создание необходимых директорий..."
mkdir -p pretrained pretrained_v2 uvr5_weights uvr5_weights/onnx_dereverb_By_FoxJoy

# Базовая модель Hubert
echo ""
echo "Скачивание hubert_base.pt..."
if [ ! -f "hubert_base.pt" ]; then
    download_file "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/hubert_base.pt" "hubert_base.pt"
else
    echo "hubert_base.pt уже существует, пропускаем..."
fi

# Модели v1 - 40k (рекомендуется)
echo ""
echo "Скачивание моделей v1 (40k)..."

# Проверяем каждый файл перед скачиванием
if [ ! -f "pretrained/f0D40k.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/f0D40k.pth" "pretrained"
else
    echo "pretrained/f0D40k.pth уже существует, пропускаем..."
fi

if [ ! -f "pretrained/f0G40k.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/f0G40k.pth" "pretrained"
else
    echo "pretrained/f0G40k.pth уже существует, пропускаем..."
fi

if [ ! -f "pretrained/D40k.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/D40k.pth" "pretrained"
else
    echo "pretrained/D40k.pth уже существует, пропускаем..."
fi

if [ ! -f "pretrained/G40k.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/G40k.pth" "pretrained"
else
    echo "pretrained/G40k.pth уже существует, пропускаем..."
fi

# Модели v1 - 32k и 48k (опционально)
echo ""
echo "Скачивание дополнительных моделей v1 (32k и 48k)..."

# 32k модели
if [ ! -f "pretrained/f0D32k.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/f0D32k.pth" "pretrained"
else
    echo "pretrained/f0D32k.pth уже существует, пропускаем..."
fi

if [ ! -f "pretrained/f0G32k.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/f0G32k.pth" "pretrained"
else
    echo "pretrained/f0G32k.pth уже существует, пропускаем..."
fi

if [ ! -f "pretrained/D32k.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/D32k.pth" "pretrained"
else
    echo "pretrained/D32k.pth уже существует, пропускаем..."
fi

if [ ! -f "pretrained/G32k.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/G32k.pth" "pretrained"
else
    echo "pretrained/G32k.pth уже существует, пропускаем..."
fi

# 48k модели
if [ ! -f "pretrained/f0D48k.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/f0D48k.pth" "pretrained"
else
    echo "pretrained/f0D48k.pth уже существует, пропускаем..."
fi

if [ ! -f "pretrained/f0G48k.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/f0G48k.pth" "pretrained"
else
    echo "pretrained/f0G48k.pth уже существует, пропускаем..."
fi

if [ ! -f "pretrained/D48k.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/D48k.pth" "pretrained"
else
    echo "pretrained/D48k.pth уже существует, пропускаем..."
fi

if [ ! -f "pretrained/G48k.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/G48k.pth" "pretrained"
else
    echo "pretrained/G48k.pth уже существует, пропускаем..."
fi

# Модели v2 (если планируете использовать v2)
echo ""
echo "Скачивание моделей v2..."

if [ ! -f "pretrained_v2/f0D40k.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained_v2/f0D40k.pth" "pretrained_v2"
else
    echo "pretrained_v2/f0D40k.pth уже существует, пропускаем..."
fi

if [ ! -f "pretrained_v2/f0G40k.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained_v2/f0G40k.pth" "pretrained_v2"
else
    echo "pretrained_v2/f0G40k.pth уже существует, пропускаем..."
fi

if [ ! -f "pretrained_v2/D40k.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained_v2/D40k.pth" "pretrained_v2"
else
    echo "pretrained_v2/D40k.pth уже существует, пропускаем..."
fi

if [ ! -f "pretrained_v2/G40k.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained_v2/G40k.pth" "pretrained_v2"
else
    echo "pretrained_v2/G40k.pth уже существует, пропускаем..."
fi

# UVR5 модели для разделения вокала
echo ""
echo "Скачивание UVR5 моделей..."

if [ ! -f "uvr5_weights/HP2-人声vocals+非人声instrumentals.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/uvr5_weights/HP2-人声vocals+非人声instrumentals.pth" "uvr5_weights"
else
    echo "HP2 модель уже существует, пропускаем..."
fi

if [ ! -f "uvr5_weights/HP5-主旋律人声vocals+其他instrumentals.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/uvr5_weights/HP5-主旋律人声vocals+其他instrumentals.pth" "uvr5_weights"
else
    echo "HP5 модель уже существует, пропускаем..."
fi

# Дополнительные UVR5 модели
echo ""
echo "Скачивание дополнительных UVR5 моделей..."

if [ ! -f "uvr5_weights/HP2_all_vocals.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/uvr5_weights/HP2_all_vocals.pth" "uvr5_weights"
else
    echo "HP2_all_vocals.pth уже существует, пропускаем..."
fi

if [ ! -f "uvr5_weights/HP3_all_vocals.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/uvr5_weights/HP3_all_vocals.pth" "uvr5_weights"
else
    echo "HP3_all_vocals.pth уже существует, пропускаем..."
fi

if [ ! -f "uvr5_weights/HP5_only_main_vocal.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/uvr5_weights/HP5_only_main_vocal.pth" "uvr5_weights"
else
    echo "HP5_only_main_vocal.pth уже существует, пропускаем..."
fi

if [ ! -f "uvr5_weights/VR-DeEchoAggressive.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/uvr5_weights/VR-DeEchoAggressive.pth" "uvr5_weights"
else
    echo "VR-DeEchoAggressive.pth уже существует, пропускаем..."
fi

if [ ! -f "uvr5_weights/VR-DeEchoDeReverb.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/uvr5_weights/VR-DeEchoDeReverb.pth" "uvr5_weights"
else
    echo "VR-DeEchoDeReverb.pth уже существует, пропускаем..."
fi

if [ ! -f "uvr5_weights/VR-DeEchoNormal.pth" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/uvr5_weights/VR-DeEchoNormal.pth" "uvr5_weights"
else
    echo "VR-DeEchoNormal.pth уже существует, пропускаем..."
fi

if [ ! -f "uvr5_weights/onnx_dereverb_By_FoxJoy/vocals.onnx" ]; then
    download_to_dir "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/uvr5_weights/onnx_dereverb_By_FoxJoy/vocals.onnx" "uvr5_weights/onnx_dereverb_By_FoxJoy"
else
    echo "vocals.onnx уже существует, пропускаем..."
fi

# RMVPE модель (для извлечения pitch)
echo ""
echo "Скачивание RMVPE модели..."
if [ ! -f "rmvpe.pt" ]; then
    download_file "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/rmvpe.pt" "rmvpe.pt"
else
    echo "rmvpe.pt уже существует, пропускаем..."
fi

echo ""
echo "=== Загрузка завершена! ==="
echo ""
echo "Проверка скачанных файлов:"
echo "----------------------"
echo "Основные модели:"
ls -la hubert_base.pt 2>/dev/null || echo "hubert_base.pt - НЕ НАЙДЕН"
ls -la rmvpe.pt 2>/dev/null || echo "rmvpe.pt - НЕ НАЙДЕН"
echo ""
echo "Pretrained v1:"
ls -la pretrained/*.pth 2>/dev/null | wc -l | xargs -I {} echo "Найдено {} файлов"
echo ""
echo "Pretrained v2:"
ls -la pretrained_v2/*.pth 2>/dev/null | wc -l | xargs -I {} echo "Найдено {} файлов"
echo ""
echo "UVR5 модели:"
ls -la uvr5_weights/*.pth 2>/dev/null | wc -l | xargs -I {} echo "Найдено {} файлов"
echo "----------------------" 