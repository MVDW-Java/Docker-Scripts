#!/bin/bash

# Function to check if GPU is working
check_gpu() {
    python3 -c "import torch; print('GPU available:', torch.cuda.is_available() if hasattr(torch.cuda, 'is_available') else torch.backends.mps.is_available() if hasattr(torch.backends, 'mps') else False)"
}

# Try to start normally
if python3 main.py --listen 0.0.0.0 --port 8188; then
    exit 0
fi

# If normal start fails, try with --force-cpu
echo "GPU initialization failed, falling back to CPU mode..."
exec python3 main.py --listen 0.0.0.0 --port 8188 --force-cpu
