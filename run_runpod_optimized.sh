#!/bin/bash

# Быстрый запуск оптимизированной версии для RunPod

echo "🚀 Запуск оптимизированной версии Mangio RVC для RunPod..."
echo ""

# Автоматическая оптимизация под GPU
if [ -f "optimize_for_gpu.py" ]; then
    echo "🔧 Запуск автооптимизации под вашу GPU..."
    python optimize_for_gpu.py
    echo ""
fi

# Запуск с docker-compose
if command -v docker-compose &> /dev/null; then
    docker-compose -f docker-compose.runpod.optimized.yml up -d
else
    docker compose -f docker-compose.runpod.optimized.yml up -d
fi

echo ""
echo "✅ Контейнер запущен!"
echo ""
echo "📊 Просмотр логов:"
echo "   docker-compose -f docker-compose.runpod.optimized.yml logs -f"
echo ""
echo "🛑 Остановка:"
echo "   docker-compose -f docker-compose.runpod.optimized.yml down" 