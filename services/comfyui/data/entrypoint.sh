#!/bin/bash

# Function to check if GPU is working
check_gpu() {
    python3 -c "import torch; print('GPU available:', torch.cuda.is_available() if hasattr(torch.cuda, 'is_available') else torch.backends.mps.is_available() if hasattr(torch.backends, 'mps') else False)"
}

# Function to install custom nodes
install_custom_nodes() {
    if [ -f "/app/config.yaml" ]; then
        # Read custom nodes from config.yaml and install them
        custom_nodes=$(python3 -c "
import yaml
with open('/app/config.yaml', 'r') as f:
    config = yaml.safe_load(f)
if 'custom_nodes' in config:
    for node in config['custom_nodes']:
        print(node)
")

        if [ ! -z "$custom_nodes" ]; then
            echo "Installing custom nodes..."
            while IFS= read -r node; do
                if [ ! -z "$node" ]; then
                    echo "Installing node from: $node"
                    git clone "$node" "custom_nodes/$(basename "$node" .git)"
                    if [ -f "custom_nodes/$(basename "$node" .git)/requirements.txt" ]; then
                        pip install -r "custom_nodes/$(basename "$node" .git)/requirements.txt"
                    fi
                fi
            done <<< "$custom_nodes"
        fi
    fi
}

# Function to configure server settings
configure_server() {
    if [ -f "/app/config.yaml" ]; then
        # Create a Python script to update the ComfyUI config
        python3 -c "
import yaml
import json
import os

# Load settings from config.yaml
with open('/app/config.yaml', 'r') as f:
    config = yaml.safe_load(f)

# Create the ComfyUI config structure
comfy_config = {}

# Server settings
if 'server' in config:
    comfy_config.update(config['server'])

# Optimization settings
if 'optimization' in config:
    comfy_config.update(config['optimization'])

# Write the config file
with open('/app/extra_model_paths.yaml', 'w') as f:
    yaml.dump({
        'folders': {
            'checkpoints': 'models/checkpoints',
            'clip': 'models/clip',
            'clip_vision': 'models/clip_vision',
            'configs': 'models/configs',
            'controlnet': 'models/controlnet',
            'embeddings': 'models/embeddings',
            'loras': 'models/loras',
            'upscale_models': 'models/upscale_models',
            'vae': 'models/vae'
        }
    }, f)
"
    fi
}

# Install custom nodes
install_custom_nodes

# Configure server settings
configure_server

# Try to start normally
if python3 main.py --listen 0.0.0.0 --port 8188; then
    exit 0
fi

# If normal start fails, try with --force-cpu
echo "GPU initialization failed, falling back to CPU mode..."
exec python3 main.py --listen 0.0.0.0 --port 8188 --force-cpu
