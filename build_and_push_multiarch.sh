#!/bin/bash

# Скрипт для многоархитектурной сборки Docker образа Mangio RVC
# Поддержка Intel (amd64) и Apple Silicon (arm64)

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Настройки по умолчанию
DOCKER_USERNAME=${DOCKER_USERNAME:-""}
IMAGE_NAME=${IMAGE_NAME:-"mangio-rvc-mac"}
VERSION=${VERSION:-"latest"}

# Функция для вывода сообщений
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Помощь
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Использование: $0 [ОПЦИИ]"
    echo ""
    echo "Многоархитектурная сборка для Intel и Apple Silicon Mac"
    echo ""
    echo "Опции:"
    echo "  -u, --username <username>    Docker Hub username (обязательно)"
    echo "  -n, --name <name>           Имя образа (по умолчанию: mangio-rvc-mac)"
    echo "  -v, --version <version>     Версия/тег образа (по умолчанию: latest)"
    echo "  --no-cache                  Сборка без кэша"
    echo "  -h, --help                  Показать это сообщение"
    echo ""
    echo "Примеры:"
    echo "  $0 -u myusername"
    echo "  $0 -u myusername -n my-rvc -v 1.0.0 --no-cache"
    exit 0
fi

# Парсинг аргументов
NO_CACHE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--username)
            DOCKER_USERNAME="$2"
            shift 2
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        *)
            error "Неизвестный аргумент: $1"
            echo "Используйте $0 --help для справки"
            exit 1
            ;;
    esac
done

# Проверка обязательных параметров
if [[ -z "$DOCKER_USERNAME" ]]; then
    error "Docker username не указан! Используйте -u или --username"
    exit 1
fi

# Полное имя образа
FULL_IMAGE_NAME="${DOCKER_USERNAME}/${IMAGE_NAME}"

# Проверка Docker
if ! command -v docker &> /dev/null; then
    error "Docker не установлен! Установите Docker Desktop для Mac"
    exit 1
fi

# Проверка buildx
log "Проверка Docker buildx..."
if ! docker buildx version &> /dev/null; then
    error "Docker buildx не найден!"
    exit 1
fi

# Создание или использование существующего builder
BUILDER_NAME="mangio-rvc-builder"
if ! docker buildx ls | grep -q "$BUILDER_NAME"; then
    log "Создание multi-platform builder..."
    docker buildx create --name "$BUILDER_NAME" --use --driver docker-container
else
    log "Использование существующего builder: $BUILDER_NAME"
    docker buildx use "$BUILDER_NAME"
fi

# Запуск builder
log "Запуск builder..."
docker buildx inspect --bootstrap

# Проверка доступных платформ
info "Доступные платформы:"
docker buildx inspect --bootstrap | grep Platforms

# Проверка авторизации
log "Проверка авторизации в Docker Hub..."
if ! docker pull hello-world &> /dev/null; then
    log "Требуется авторизация в Docker Hub"
    docker login
    if [[ $? -ne 0 ]]; then
        error "Не удалось авторизоваться в Docker Hub"
        exit 1
    fi
fi

# Проверка наличия моделей
if [[ ! -f "hubert_base.pt" ]] || [[ ! -d "pretrained" ]]; then
    warning "Модели не найдены! Запускаем скрипт загрузки..."
    if [[ -f "download_models.sh" ]]; then
        chmod +x download_models.sh
        ./download_models.sh
    else
        error "Скрипт download_models.sh не найден!"
        exit 1
    fi
fi

# Многоархитектурная сборка
log "Начинаем многоархитектурную сборку..."
log "Образ: ${FULL_IMAGE_NAME}:${VERSION}"
log "Платформы: linux/amd64, linux/arm64"

# Сборка и отправка
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -f Dockerfile.mac \
    -t "${FULL_IMAGE_NAME}:${VERSION}" \
    --push \
    $NO_CACHE \
    .

if [[ $? -ne 0 ]]; then
    error "Ошибка при сборке образа!"
    exit 1
fi

# Если версия не latest, добавляем тег latest
if [[ "$VERSION" != "latest" ]]; then
    log "Добавление тега latest..."
    docker buildx build \
        --platform linux/amd64,linux/arm64 \
        -f Dockerfile.mac \
        -t "${FULL_IMAGE_NAME}:latest" \
        --push \
        .
fi

# Информация об образе
log "Многоархитектурный образ успешно собран и отправлен!"
echo ""
echo "Образ доступен по адресу:"
echo "  ${FULL_IMAGE_NAME}:${VERSION} (linux/amd64, linux/arm64)"
if [[ "$VERSION" != "latest" ]]; then
    echo "  ${FULL_IMAGE_NAME}:latest (linux/amd64, linux/arm64)"
fi
echo ""
echo "Для запуска на любом Mac используйте:"
echo "  docker run -d -p 7865:7865 ${FULL_IMAGE_NAME}:${VERSION}"
echo ""
info "Этот образ будет работать как на Intel Mac, так и на Apple Silicon!"

log "Готово!" 