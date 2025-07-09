#!/bin/bash

# Скрипт для сборки и публикации Docker образа Mangio RVC для RunPod
# Использует CUDA и оптимизирован для облачных GPU

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Настройки по умолчанию
DOCKER_USERNAME=${DOCKER_USERNAME:-""}
IMAGE_NAME=${IMAGE_NAME:-"mangio-rvc-runpod"}
VERSION=${VERSION:-"latest"}
OPTIMIZED=${OPTIMIZED:-false}
DOCKERFILE="Dockerfile.optimized"

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
    echo "Сборка Docker образа Mangio RVC для RunPod (CUDA + NVIDIA GPU)"
    echo ""
    echo "Опции:"
    echo "  -u, --username <username>    Docker Hub username (обязательно)"
    echo "  -n, --name <name>           Имя образа (по умолчанию: mangio-rvc-runpod)"
    echo "  -v, --version <version>     Версия/тег образа (по умолчанию: latest)"
    echo "  --no-cache                  Сборка без кэша"
    echo "  --push-only                 Только отправка (без сборки)"
    echo "  --optimized                 Использовать оптимизированную версию (CUDA 12.1)"
    echo "  -h, --help                  Показать это сообщение"
    echo ""
    echo "Примеры:"
    echo "  $0 -u myusername"
    echo "  $0 -u myusername -n my-rvc-runpod -v 1.0.0"
    echo ""
    echo "После публикации используйте в RunPod:"
    echo "  Image: myusername/mangio-rvc-runpod:latest"
    echo "  Port: 3000"
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
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        --push-only)
            PUSH_ONLY=true
            shift
            ;;
        --optimized)
            OPTIMIZED=true
            DOCKERFILE="Dockerfile.runpod.optimized"
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
    error "Docker не установлен!"
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
    error "Docker не запущен!"
    exit 1
fi

# Проверка авторизации в Docker Hub
log "Проверка авторизации в Docker registry..."
if ! docker pull hello-world &> /dev/null; then
    log "Требуется авторизация в Docker registry"
    docker login
    if [[ $? -ne 0 ]]; then
        error "Не удалось авторизоваться в Docker registry"
        exit 1
    fi
fi

# Сборка образа
if [[ "$PUSH_ONLY" == false ]]; then
    log "Начинаем сборку Docker образа для RunPod..."
    log "Образ: ${FULL_IMAGE_NAME}:${VERSION}"
    if [[ "$OPTIMIZED" == true ]]; then
        log "Dockerfile: ${DOCKERFILE} (CUDA 12.1 + Оптимизации)"
    else
        log "Dockerfile: ${DOCKERFILE} (CUDA 11.8)"
    fi
    
    # Проверка buildx для многоархитектурной сборки
    if ! docker buildx version &> /dev/null; then
        error "Docker buildx не найден! Требуется для сборки CUDA образа на Apple Silicon"
        exit 1
    fi
fi

# Определение архитектуры (вне блока if)
ARCH=$(uname -m)

if [[ "$PUSH_ONLY" == false ]]; then
    if [[ "$ARCH" == "arm64" ]]; then
        warning "Обнаружен Apple Silicon! Используем buildx для сборки AMD64 образа..."
        
        # Создание builder если нужно
        BUILDER_NAME="runpod-builder"
        if ! docker buildx ls | grep -q "$BUILDER_NAME"; then
            log "Создание buildx builder для AMD64..."
            docker buildx create --name "$BUILDER_NAME" --use --driver docker-container
        else
            docker buildx use "$BUILDER_NAME"
        fi
        
        # Запуск builder
        docker buildx inspect --bootstrap
        
        # Многоархитектурная сборка для AMD64
        log "Сборка AMD64 образа с помощью buildx..."
        docker buildx build \
            --platform linux/amd64 \
            -f ${DOCKERFILE} \
            -t "${FULL_IMAGE_NAME}:${VERSION}" \
            --push \
            $NO_CACHE \
            .
        
        if [[ $? -ne 0 ]]; then
            error "Ошибка при сборке образа!"
            exit 1
        fi
        
        # Дополнительный тег latest если нужно
        if [[ "$VERSION" != "latest" ]]; then
            docker buildx build \
                --platform linux/amd64 \
                -f ${DOCKERFILE} \
                -t "${FULL_IMAGE_NAME}:latest" \
                --push \
                .
        fi
        
        log "Образ успешно собран и отправлен через buildx!"
        
    else
        log "Обнаружен Intel/AMD64 Mac. Сборка обычным способом..."
        
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
        
        # Сборка с docker-compose для RunPod (только для Intel Mac)
        log "Сборка образа с помощью docker-compose (RunPod конфигурация)..."
        $COMPOSE_CMD -f docker-compose.runpod.yml build $NO_CACHE
        
        if [[ $? -ne 0 ]]; then
            error "Ошибка при сборке образа!"
            exit 1
        fi
        
        # Тегирование образа
        log "Тегирование образа..."
        docker tag mangio-rvc-runpod:latest "${FULL_IMAGE_NAME}:${VERSION}"
        
        if [[ "$VERSION" != "latest" ]]; then
            docker tag mangio-rvc-runpod:latest "${FULL_IMAGE_NAME}:latest"
        fi
        
        # Отправка в registry для Intel Mac
        log "Отправка образа в registry..."
        docker push "${FULL_IMAGE_NAME}:${VERSION}"

        if [[ $? -ne 0 ]]; then
            error "Ошибка при отправке образа!"
            exit 1
        fi

        if [[ "$VERSION" != "latest" ]]; then
            docker push "${FULL_IMAGE_NAME}:latest"
        fi
    fi
fi

# Информация об образе
log "Образ для RunPod успешно собран и отправлен!"
echo ""
echo "Образ доступен по адресу:"
echo "  ${FULL_IMAGE_NAME}:${VERSION}"
if [[ "$VERSION" != "latest" ]]; then
    echo "  ${FULL_IMAGE_NAME}:latest"
fi
echo ""
info "🚀 Настройки для RunPod:"
echo "  Docker Image: ${FULL_IMAGE_NAME}:${VERSION}"
echo "  Exposed Port: 3000"
if [[ "$OPTIMIZED" == true ]]; then
    echo "  GPU Support: NVIDIA CUDA 12.1 (Оптимизировано)"
else
    echo "  GPU Support: NVIDIA CUDA 11.8"
fi
echo ""
echo "💡 В RunPod используйте:"
echo "  1. Template: Custom"
echo "  2. Image: ${FULL_IMAGE_NAME}:${VERSION}"
echo "  3. Port: 3000"
echo "  4. Volume: /workspace (опционально)"

log "Готово!" 