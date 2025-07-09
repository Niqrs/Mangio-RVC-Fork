# 🚀 RunPod Guide для Mangio RVC

## Быстрый старт

### 1. Публикация образа для RunPod

```bash
# Стандартная версия (CUDA 11.8)
chmod +x build_and_push_runpod.sh
./build_and_push_runpod.sh -u YOUR_DOCKERHUB_USERNAME

# Оптимизированная версия (CUDA 12.1 + оптимизации) ⚡
./build_and_push_runpod.sh -u YOUR_DOCKERHUB_USERNAME --optimized
```

### 2. Настройка в RunPod

1. **Создать новый Pod** → **Custom Template**
2. **Настройки:**
   ```
   Docker Image: YOUR_USERNAME/mangio-rvc-runpod:latest
   Exposed Port: 3000
   GPU: Любая NVIDIA (RTX 3080/4090/A100/H100)
   ```

3. **Запустить Pod** и перейти по выданному URL

## 📋 Детальная настройка

### Template Configuration

```yaml
Docker Image: niqr/mangio-rvc-runpod:latest
Container Arguments: 
Exposed Port: 3000
Environment Variables:
  - NVIDIA_VISIBLE_DEVICES=all
  - TZ=UTC
Volume Mapping: 
  - /workspace → /app (опционально)
```

### Рекомендуемые GPU

| GPU      | VRAM    | Производительность | Цена/час | Оптимальная версия |
| -------- | ------- | ------------------ | -------- | ------------------ |
| RTX 3080 | 10GB    | Хорошо             | $0.44    | Стандартная        |
| RTX 4090 | 24GB    | Отлично            | $0.83    | Оптимизированная   |
| A100     | 40/80GB | Максимум           | $1.89+   | Оптимизированная   |
| H100     | 80GB    | Ультра             | $4.69    | Оптимизированная   |

### Оптимальные настройки Pod'а

- **CPU**: 8+ ядер
- **RAM**: 16GB+
- **Storage**: 50GB+ (для моделей и данных)
- **Network**: Высокая пропускная способность

## 🔧 Переменные окружения

```bash
# Основные
NVIDIA_VISIBLE_DEVICES=all          # Доступ ко всем GPU
TZ=UTC                              # Временная зона

# Оптимизация (опционально)
CUDA_VISIBLE_DEVICES=0              # Использовать только GPU 0
RVC_BATCH_SIZE=32                   # Размер batch для обучения
RVC_MAX_MEMORY=0.9                  # Максимальное использование VRAM
```

## 📁 Volume Mapping

### Стандартная схема:
```
/workspace/models → /app/pretrained     # Предобученные модели
/workspace/weights → /app/weights       # Ваши модели
/workspace/audio → /app/audios          # Входные аудио
/workspace/output → /app/audio-outputs  # Результаты
/workspace/datasets → /app/datasets     # Датасеты для обучения
```

## 🚀 Скрипт автозапуска

Создайте в `/workspace` файл `start_rvc.sh`:

```bash
#!/bin/bash
cd /app

# Скачивание моделей если их нет
if [ ! -f "hubert_base.pt" ]; then
    echo "Downloading models..."
    ./download_models.sh
fi

# Запуск RVC
echo "Starting Mangio RVC..."
python infer-web.py --port 3000 --noautoopen
```

И установите его как команду запуска:
```bash
Container Arguments: bash /workspace/start_rvc.sh
```

## 🚀 Оптимизированная версия

### Что включено в оптимизацию:

- **CUDA 12.1** вместо 11.8 (до 30% быстрее на новых GPU)
- **Multi-stage build** (размер образа меньше на 50%)
- **TensorRT** поддержка для inference
- **Автоматическая оптимизация** под конкретную GPU
- **Flash Attention** для A100/H100

### Запуск с автооптимизацией:

```bash
# В RunPod Pod'е:
python optimize_for_gpu.py

# Или при старте контейнера:
docker run -it YOUR_USERNAME/mangio-rvc-runpod:latest python optimize_for_gpu.py && python infer-web.py --port 3000
```

## ⚡ Производительность

### Ожидаемые времена обработки:

| Операция           | RTX 3080 | RTX 4090 | A100     | A100 (опт.) |
| ------------------ | -------- | -------- | -------- | ----------- |
| Inference (30s)    | 3-5s     | 2-3s     | 1-2s     | 0.5-1s      |
| Training (1 epoch) | 30-45s   | 20-30s   | 10-15s   | 5-10s       |
| Feature extraction | 2-3 min  | 1-2 min  | 30s-1min | 15-30s      |

### Оптимизация производительности:

1. **Batch Size**: Увеличьте до максимума (VRAM)
2. **Mixed Precision**: Автоматически включается на современных GPU
3. **DataLoader Workers**: 4-8 потоков для загрузки данных

## 🛠️ Troubleshooting

### Проблема: OOM (Out of Memory)
```bash
# Решение: Уменьшить batch size
echo "export RVC_BATCH_SIZE=16" >> ~/.bashrc
```

### Проблема: Медленная загрузка моделей
```bash
# Решение: Предзагрузить модели в образ
# Или использовать персистентный том
```

### Проблема: Сетевые ошибки
```bash
# Проверить соединение
curl -I https://huggingface.co/
```

## 💡 Pro Tips

1. **Persistent Storage**: Используйте Network Volume для сохранения моделей между сессиями
2. **Template Sharing**: Создайте template и поделитесь с командой
3. **Auto-scaling**: Используйте Serverless для автоматического масштабирования
4. **Cost Optimization**: Останавливайте Pod'ы когда не используете

## 📊 Monitoring

### Проверка GPU использования:
```bash
# В терминале Pod'а
nvidia-smi -l 1
```

### Проверка логов:
```bash
# Логи контейнера
docker logs mangio-rvc-runpod -f
```

## 🔗 Полезные ссылки

- [RunPod Documentation](https://docs.runpod.io/)
- [CUDA Compatibility](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/)
- [PyTorch GPU Guide](https://pytorch.org/get-started/locally/)

---

**Готово!** Теперь у вас есть мощная облачная платформа для работы с Mangio RVC! 🎵 