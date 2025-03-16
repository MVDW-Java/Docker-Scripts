source ../../core/build.sh
source ../../core/backup.sh
source ../../core/run.sh

# safety when an error occurs
set -e

# Detect GPU and set appropriate runtime options
detect_gpu_runtime() {
    if command -v nvidia-smi &> /dev/null; then
        echo "--gpus all"
    elif [ -d "/dev/dri" ]; then
        echo "--device \"/dev/dri:/dev/dri\" --device \"/dev/kfd:/dev/kfd\" --group-add video" # --security-opt seccomp=unconfined
    else
        echo ""
    fi
}

# Get GPU runtime options
GPU_OPTIONS=$(detect_gpu_runtime)

# build and deploy
DockerBuild comfyui $(pwd)/data/Dockerfile

DockerBackup -n comfyui

# Base command with additional environment variables
CMD=(DockerRun \
    -i "comfyui" \
    -n "comfyui" \
    --network "comfyui" \
    -p "8188:8188" \
    -v "comfyui-models:/app/models" \
    -v "comfyui-input:/app/input" \
    -v "comfyui-output:/app/output" \
    -v "comfyui-custom-nodes:/app/custom_nodes" \
    -e "HSA_OVERRIDE_GFX_VERSION=10.3.0" \
    -e "PYTORCH_ROCM_ARCH=gfx1030" \
    --group-add "$(getent group docker | cut -d: -f3)" \
    --restart "unless-stopped")

# Add GPU options if available
if [ -n "$GPU_OPTIONS" ]; then
    read -ra OPTS <<< "$GPU_OPTIONS"
    CMD+=("${OPTS[@]}")
fi

# Add detach flag
CMD+=("-d")

# Execute the command
"${CMD[@]}"
