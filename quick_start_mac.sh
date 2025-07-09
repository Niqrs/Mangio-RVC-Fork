#!/bin/bash

# Быстрый запуск Mangio RVC на macOS

echo "🎵 Mangio RVC Fork - Быстрый запуск для macOS"
echo "============================================"

# Определение архитектуры
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    echo "🚀 Обнаружен Apple Silicon ($ARCH) - будет использоваться MPS ускорение!"
else
    echo "💻 Обнаружен Intel Mac ($ARCH) - будет использоваться CPU"
fi
echo ""

# Проверка Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker не установлен!"
    echo "Пожалуйста, установите Docker Desktop для Mac:"
    echo "https://www.docker.com/products/docker-desktop/"
    exit 1
fi

# Проверка что Docker запущен
if ! docker info &> /dev/null 2>&1; then
    echo "❌ Docker не запущен!"
    echo "Запустите Docker Desktop и попробуйте снова."
    exit 1
fi

# Проверка моделей
if [[ ! -f "hubert_base.pt" ]] || [[ ! -d "pretrained" ]]; then
    echo "📥 Скачивание необходимых моделей..."
    chmod +x download_models.sh
    ./download_models.sh
fi

# Определение команды docker-compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

# Сборка
echo ""
echo "🔨 Сборка Docker образа..."
$COMPOSE_CMD -f docker-compose.mac.yml build

if [[ $? -ne 0 ]]; then
    echo "❌ Ошибка при сборке!"
    exit 1
fi

# Запуск
echo ""
echo "🚀 Запуск контейнера..."
$COMPOSE_CMD -f docker-compose.mac.yml up -d

if [[ $? -ne 0 ]]; then
    echo "❌ Ошибка при запуске!"
    exit 1
fi

# Ожидание запуска
echo ""
echo "⏳ Ожидание запуска приложения..."
sleep 5

# Проверка статуса
if docker ps | grep -q mangio-rvc-mac; then
    echo ""
    echo "✅ Mangio RVC успешно запущен!"
    echo ""
    echo "🌐 Откройте в браузере: http://localhost:7865"
    echo ""
    echo "📋 Полезные команды:"
    echo "  Просмотр логов:    $COMPOSE_CMD -f docker-compose.mac.yml logs -f"
    echo "  Остановка:         $COMPOSE_CMD -f docker-compose.mac.yml down"
    echo "  Перезапуск:        $COMPOSE_CMD -f docker-compose.mac.yml restart"
    echo ""
    
    # Информация о MPS для Apple Silicon
    if [[ "$ARCH" == "arm64" ]]; then
        echo "⚡ Проверить MPS ускорение:"
        echo "  $COMPOSE_CMD -f docker-compose.mac.yml logs | grep MPS"
        echo ""
    fi
    
    # Предложение открыть браузер
    read -p "Открыть в браузере сейчас? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open http://localhost:7865
    fi
else
    echo "❌ Контейнер не запустился. Проверьте логи:"
    echo "$COMPOSE_CMD -f docker-compose.mac.yml logs"
fi 