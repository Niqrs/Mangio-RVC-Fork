# Docker Setup для Mangio RVC Fork 🐳

Это руководство поможет вам запустить Mangio RVC Fork в Docker контейнере.

## 🍎 Специально для macOS

Если вы используете Mac, используйте специальные команды для macOS:

```bash
# Сборка Docker образа для Mac
docker-compose -f docker-compose.mac.yml build

# Запуск контейнера
docker-compose -f docker-compose.mac.yml up -d

# Просмотр логов
docker-compose -f docker-compose.mac.yml logs -f
```

После успешного запуска откройте: http://localhost:7865

### 🚀 Примечания для Mac:
- **На Apple Silicon (M1/M2/M3/M4)**: Автоматически использует **MPS (Metal Performance Shaders)** для GPU ускорения 🔥
- **На Intel Mac**: Работает на CPU
- Первая сборка может занять 15-30 минут
- **M4 Pro/Max/Ultra** получают максимальное ускорение благодаря MPS

### ⚡ Проверка MPS ускорения:

В логах контейнера вы увидите:
```
No supported Nvidia GPU found, use MPS instead
```

Это означает, что используется GPU ускорение через Metal!

## 📋 Предварительные требования

### Для GPU версии:
- Docker и Docker Compose
- NVIDIA GPU с поддержкой CUDA 11.8+
- NVIDIA Docker runtime (nvidia-docker2)
- Минимум 8GB VRAM (рекомендуется 12GB+)

### Для CPU версии:
- Docker и Docker Compose
- Минимум 16GB RAM
- Мощный процессор (рекомендуется 8+ ядер)

## 🚀 Быстрый старт

### Шаг 1: Скачивание предобученных моделей

Сначала сделайте скрипт исполняемым и запустите загрузку моделей:

```bash
chmod +x download_models.sh
./download_models.sh
```

Это скачает все необходимые модели (~3GB). Скрипт проверяет существующие файлы и не скачивает их повторно.

### Шаг 2: Сборка и запуск

#### Вариант A: С поддержкой GPU (рекомендуется)

```bash
# Сборка Docker образа
docker-compose build

# Запуск контейнера в фоновом режиме
docker-compose up -d

# Просмотр логов
docker-compose logs -f
```

#### Вариант B: Только CPU (медленнее)

```bash
# Сборка Docker образа для CPU
docker-compose -f docker-compose.cpu.yml build

# Запуск контейнера
docker-compose -f docker-compose.cpu.yml up -d

# Просмотр логов
docker-compose -f docker-compose.cpu.yml logs -f
```

### Шаг 3: Доступ к веб-интерфейсу

После успешного запуска откройте в браузере:
```
http://localhost:7865
```

## 🔧 Дополнительные команды

### Остановка контейнера
```bash
docker-compose down
```

### Перезапуск контейнера
```bash
docker-compose restart
```

### Обновление после изменений
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Вход в контейнер для отладки
```bash
docker-compose exec mangio-rvc bash
```

## 📁 Структура директорий

После запуска будут созданы следующие директории:

- `./logs/` - Логи тренировки и модели
- `./weights/` - Веса обученных моделей  
- `./audio-outputs/` - Результаты обработки аудио
- `./datasets/` - Датасеты для тренировки
- `./audios/` - Входные аудио файлы

Все эти директории автоматически монтируются в контейнер, поэтому данные сохраняются между перезапусками.

## ⚠️ Возможные проблемы и решения

### 1. Ошибка "nvidia-docker runtime not found"

Установите nvidia-docker2:
```bash
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update && sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker
```

### 2. Недостаточно памяти GPU

Уменьшите batch size в настройках тренировки или используйте CPU версию.

### 3. Порт 7865 занят

Измените порт в docker-compose.yml:
```yaml
ports:
  - "8080:7865"  # Изменить на любой свободный порт
```

### 4. Ошибки с правами доступа

Запустите:
```bash
sudo chmod -R 777 logs weights audio-outputs datasets audios
```

## 🛠️ Настройка производительности

### Для GPU версии

В `docker-compose.yml` можно настроить:

```yaml
environment:
  - NVIDIA_VISIBLE_DEVICES=0  # Использовать конкретную GPU
  - CUDA_VISIBLE_DEVICES=0    # Альтернативный способ
```

### Для CPU версии

В `docker-compose.cpu.yml` можно изменить лимиты:

```yaml
deploy:
  resources:
    limits:
      cpus: '16'      # Количество ядер CPU
      memory: 32G     # Объем RAM
```

## 📝 Примечания

1. **Первый запуск** может занять 10-20 минут на установку зависимостей
2. **GPU версия** работает в 10-50 раз быстрее CPU версии
3. **Модели v2** требуют больше памяти, но дают лучшее качество
4. **UVR5 модели** используются для отделения вокала от музыки

## 🔄 Обновление

Для обновления до новой версии:

```bash
git pull
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## 🤝 Поддержка

При возникновении проблем:
1. Проверьте логи: `docker-compose logs`
2. Убедитесь, что все модели скачаны: `ls -la pretrained/`
3. Проверьте версию Docker: `docker --version`
4. Для GPU: проверьте CUDA: `nvidia-smi`

## 🚀 Публикация образа в Docker Hub

### Обычная сборка (для текущей архитектуры)

```bash
# Сделать скрипт исполняемым
chmod +x build_and_push.sh

# Собрать и опубликовать образ
./build_and_push.sh -u YOUR_DOCKERHUB_USERNAME

# С дополнительными опциями
./build_and_push.sh -u YOUR_USERNAME -n custom-name -v 1.0.0
```

### Многоархитектурная сборка (Intel + Apple Silicon)

Рекомендуется для публичных образов:

```bash
# Сделать скрипт исполняемым
chmod +x build_and_push_multiarch.sh

# Собрать для обеих архитектур
./build_and_push_multiarch.sh -u YOUR_DOCKERHUB_USERNAME
```

### Опции скриптов

- `-u, --username` - Docker Hub username (обязательно)
- `-n, --name` - Имя образа (по умолчанию: mangio-rvc-mac)
- `-v, --version` - Версия/тег (по умолчанию: latest)
- `--no-cache` - Сборка без кэша
- `-h, --help` - Показать справку

### Использование опубликованного образа

После публикации любой может использовать ваш образ:

```bash
# Запуск опубликованного образа
docker run -d -p 7865:7865 YOUR_USERNAME/mangio-rvc-mac:latest

# Или через docker-compose
# Измените в docker-compose.mac.yml:
# image: YOUR_USERNAME/mangio-rvc-mac:latest
docker-compose -f docker-compose.mac.yml up -d
```

## ☁️ Запуск на RunPod (облачные GPU)

Для использования мощных облачных GPU на RunPod:

### 1. Сборка образа для RunPod:
```bash
chmod +x build_and_push_runpod.sh
./build_and_push_runpod.sh -u YOUR_DOCKERHUB_USERNAME
```

### 2. Настройка в RunPod:
- **Docker Image**: `YOUR_USERNAME/mangio-rvc-runpod:latest`
- **Exposed Port**: `3000`
- **GPU**: Любая NVIDIA (RTX 3080/4090/A100/H100)

### 3. Преимущества RunPod:
- 🚀 **Мощные GPU**: RTX 4090, A100, H100
- ⚡ **Быстрая обработка**: В 10-50 раз быстрее CPU
- 💰 **Оплата по факту**: От $0.44/час
- 🌐 **Доступ из браузера**: Не нужно локальное железо

📖 **Подробное руководство**: см. [RUNPOD_GUIDE.md](./RUNPOD_GUIDE.md)

---

Удачного использования Mangio RVC Fork! 🎵 