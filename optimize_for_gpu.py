#!/usr/bin/env python3
"""
Автоматическая оптимизация Mangio RVC под конкретную GPU
"""

import torch
import os
import json
from pathlib import Path

class GPUOptimizer:
    def __init__(self):
        self.gpu_available = torch.cuda.is_available()
        self.gpu_name = None
        self.gpu_memory = 0
        self.optimizations = {}
        
        if self.gpu_available:
            self.gpu_name = torch.cuda.get_device_name(0)
            self.gpu_memory = torch.cuda.get_device_properties(0).total_memory // (1024**3)
            print(f"🎮 Обнаружена GPU: {self.gpu_name} ({self.gpu_memory}GB)")
        else:
            print("⚠️  GPU не обнаружена, используется CPU режим")
    
    def detect_gpu_capabilities(self):
        """Определение возможностей GPU"""
        if not self.gpu_available:
            return
        
        compute_capability = torch.cuda.get_device_capability(0)
        self.optimizations['compute_capability'] = f"{compute_capability[0]}.{compute_capability[1]}"
        
        try:
            import tensorrt
            self.optimizations['tensorrt'] = True
            print("✅ TensorRT поддерживается")
        except:
            self.optimizations['tensorrt'] = False
            
        if compute_capability[0] >= 8:
            self.optimizations['flash_attention'] = True
            print("✅ Flash Attention поддерживается")
        else:
            self.optimizations['flash_attention'] = False
    
    def optimize_for_gpu(self):
        """Применение оптимизаций для конкретной GPU"""
        
        os.environ["CUDA_LAUNCH_BLOCKING"] = "0"
        os.environ["CUDNN_BENCHMARK"] = "1"
        
        if self.gpu_name and ("H100" in self.gpu_name or "H800" in self.gpu_name):
            print("🚀 Применяю оптимизации для H100/H800")
            os.environ["TORCH_CUDA_ARCH_LIST"] = "9.0"
            os.environ["PYTORCH_CUDA_ALLOC_CONF"] = "max_split_size_mb:512"
            os.environ["CUDA_DEVICE_MAX_CONNECTIONS"] = "1"
            batch_size = 128
            num_workers = 16
            
        elif self.gpu_name and ("A100" in self.gpu_name or "A6000" in self.gpu_name):
            print("🚀 Применяю оптимизации для A100/A6000")
            os.environ["TORCH_CUDA_ARCH_LIST"] = "8.0;8.6"
            os.environ["PYTORCH_CUDA_ALLOC_CONF"] = "max_split_size_mb:512"
            batch_size = 64 if self.gpu_memory >= 40 else 32
            num_workers = 12
            
        elif self.gpu_name and ("4090" in self.gpu_name or "4080" in self.gpu_name):
            print("🚀 Применяю оптимизации для RTX 40 серии")
            os.environ["TORCH_CUDA_ARCH_LIST"] = "8.9"
            os.environ["TORCH_CUDNN_V8_API_ENABLED"] = "1"
            os.environ["PYTORCH_CUDA_ALLOC_CONF"] = "max_split_size_mb:256"
            batch_size = 32
            num_workers = 8
            
        elif self.gpu_name and ("3090" in self.gpu_name or "3080" in self.gpu_name):
            print("🚀 Применяю оптимизации для RTX 30 серии")
            os.environ["TORCH_CUDA_ARCH_LIST"] = "8.6"
            os.environ["PYTORCH_CUDA_ALLOC_CONF"] = "max_split_size_mb:128"
            batch_size = 16
            num_workers = 6
            
        elif self.gpu_name and "V100" in self.gpu_name:
            print("🚀 Применяю оптимизации для V100")
            os.environ["TORCH_CUDA_ARCH_LIST"] = "7.0"
            batch_size = 16
            num_workers = 4
            
        else:
            print("🚀 Применяю универсальные GPU оптимизации")
            batch_size = 8
            num_workers = 4
        
        config = {
            "gpu_name": self.gpu_name,
            "gpu_memory": self.gpu_memory,
            "batch_size": batch_size,
            "num_workers": num_workers,
            "optimizations": self.optimizations,
            "environment": {k: v for k, v in os.environ.items() if k.startswith(("CUDA", "TORCH", "PYTORCH"))}
        }
        
        with open("gpu_optimization_config.json", "w") as f:
            json.dump(config, f, indent=2)
        
        print(f"\n📊 Оптимальные настройки:")
        print(f"   • Batch size: {batch_size}")
        print(f"   • Num workers: {num_workers}")
        print(f"   • GPU память: {self.gpu_memory}GB")
        
        return batch_size, num_workers
    
    def optimize_model_configs(self, batch_size):
        """Оптимизация конфигурационных файлов моделей"""
        config_files = ["32k.json", "40k.json", "48k.json"]
        configs_dir = Path("configs")
        
        if not configs_dir.exists():
            configs_dir = Path("configs_v2")
        
        for config_file in config_files:
            config_path = configs_dir / config_file
            if config_path.exists():
                with open(config_path, "r") as f:
                    config = json.load(f)
                
                if "train" in config:
                    config["train"]["batch_size"] = batch_size
                    if self.gpu_memory >= 24:
                        config["train"]["fp16_run"] = True
                    
                    if batch_size >= 32:
                        config["train"]["learning_rate"] = 0.0002
                
                with open(config_path, "w") as f:
                    json.dump(config, f, indent=2)
                
                print(f"✅ Оптимизирован {config_file}")

def main():
    print("🔧 Запуск автоматической оптимизации GPU для Mangio RVC\n")
    
    optimizer = GPUOptimizer()
    optimizer.detect_gpu_capabilities()
    batch_size, num_workers = optimizer.optimize_for_gpu()
    optimizer.optimize_model_configs(batch_size)
    
    print("\n✨ Оптимизация завершена!")
    print("   Конфигурация сохранена в gpu_optimization_config.json")

if __name__ == "__main__":
    main()
