#!/bin/bash

# Скрипт для сборки и публикации Docker образа Mangio RVC (macOS версия)

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Настройки по умолчанию
DOCKER_REGISTRY=${DOCKER_REGISTRY:-"docker.io"}
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

# Проверка, что скрипт запущен на macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    error "Этот скрипт предназначен только для macOS!"
    exit 1
fi

# Помощь
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Использование: $0 [ОПЦИИ]"
    echo ""
    echo "Опции:"
    echo "  -u, --username <username>    Docker Hub username (обязательно)"
    echo "  -n, --name <name>           Имя образа (по умолчанию: mangio-rvc-mac)"
    echo "  -v, --version <version>     Версия/тег образа (по умолчанию: latest)"
    echo "  -r, --registry <registry>   Docker registry (по умолчанию: docker.io)"
    echo "  --no-cache                  Сборка без кэша"
    echo "  --push-only                 Только отправка (без сборки)"
    echo "  -h, --help                  Показать это сообщение"
    echo ""
    echo "Примеры:"
    echo "  $0 -u myusername"
    echo "  $0 -u myusername -n my-rvc -v 1.0.0"
    echo "  $0 -u myusername --no-cache"
    exit 0
fi

# Парсинг аргументов
NO_CACHE=""
PUSH_ONLY=false

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
        -r|--registry)
            DOCKER_REGISTRY="$2"
            shift 2
            ;;
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        --push-only)
            PUSH_ONLY=true
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
if [[ "$DOCKER_REGISTRY" == "docker.io" ]]; then
    FULL_IMAGE_NAME="${DOCKER_USERNAME}/${IMAGE_NAME}"
else
    FULL_IMAGE_NAME="${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${IMAGE_NAME}"
fi

# Проверка Docker
if ! command -v docker &> /dev/null; then
    error "Docker не установлен! Установите Docker Desktop для Mac"
    exit 1
fi

# Проверка Docker Compose
if ! command -v docker-compose &> /dev/null; then
    warning "docker-compose не найден, пробуем docker compose"
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

# Проверка что Docker запущен
if ! docker info &> /dev/null; then
    error "Docker не запущен! Запустите Docker Desktop"
    exit 1
fi

# Проверка авторизации в Docker Hub
log "Проверка авторизации в Docker registry..."
if ! docker pull hello-world &> /dev/null; then
    log "Требуется авторизация в Docker registry"
    docker login $DOCKER_REGISTRY
    if [[ $? -ne 0 ]]; then
        error "Не удалось авторизоваться в Docker registry"
        exit 1
    fi
fi

# Сборка образа
if [[ "$PUSH_ONLY" == false ]]; then
    log "Начинаем сборку Docker образа..."
    log "Образ: ${FULL_IMAGE_NAME}:${VERSION}"
    
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
    
    # Сборка с docker-compose
    log "Сборка образа с помощью docker-compose..."
    $COMPOSE_CMD -f docker-compose.mac.yml build $NO_CACHE
    
    if [[ $? -ne 0 ]]; then
        error "Ошибка при сборке образа!"
        exit 1
    fi
    
    # Тегирование образа
    log "Тегирование образа..."
    docker tag mangio-rvc-mac:latest "${FULL_IMAGE_NAME}:${VERSION}"
    
    if [[ "$VERSION" != "latest" ]]; then
        docker tag mangio-rvc-mac:latest "${FULL_IMAGE_NAME}:latest"
    fi
fi

# Отправка в registry
log "Отправка образа в registry..."
docker push "${FULL_IMAGE_NAME}:${VERSION}"

if [[ $? -ne 0 ]]; then
    error "Ошибка при отправке образа!"
    exit 1
fi

if [[ "$VERSION" != "latest" ]]; then
    docker push "${FULL_IMAGE_NAME}:latest"
fi

# Информация об образе
log "Образ успешно собран и отправлен!"
echo ""
echo "Образ доступен по адресу:"
echo "  ${FULL_IMAGE_NAME}:${VERSION}"
if [[ "$VERSION" != "latest" ]]; then
    echo "  ${FULL_IMAGE_NAME}:latest"
fi
echo ""
echo "Для запуска используйте:"
echo "  docker run -d -p 7865:7865 ${FULL_IMAGE_NAME}:${VERSION}"
echo ""
echo "Или обновите docker-compose.mac.yml:"
echo "  image: ${FULL_IMAGE_NAME}:${VERSION}"

# Опционально: очистка локальных образов
read -p "Удалить локальные промежуточные образы? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Очистка промежуточных образов..."
    docker image prune -f
fi

log "Готово!" 