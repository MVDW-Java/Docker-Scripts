# Multi-stage build to determine GPU support
FROM ubuntu:22.04 AS gpu-detect

RUN apt-get update && apt-get install -y \
    pciutils \
    && rm -rf /var/lib/apt/lists/*

COPY data/detect-gpu.sh /detect-gpu.sh
RUN chmod +x /detect-gpu.sh
RUN /detect-gpu.sh > /gpu-vendor

# Builder stage for Python packages
FROM ubuntu:22.04 AS builder

# Install Python and pip
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Copy GPU vendor information
COPY --from=gpu-detect /gpu-vendor /gpu-vendor

# Install Python packages based on GPU vendor
RUN pip3 install --no-cache-dir --upgrade pip setuptools wheel packaging && \
    GPU_VENDOR=$(cat /gpu-vendor) && \
    if [ "$GPU_VENDOR" = "NVIDIA" ]; then \
    pip3 install --no-cache-dir \
    --target /python-packages \
    torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cu121; \
    elif [ "$GPU_VENDOR" = "AMD" ]; then \
    pip3 install --no-cache-dir \
    --target /python-packages \
    torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/rocm6.0; \
    else \
    pip3 install --no-cache-dir \
    --target /python-packages \
    torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cpu; \
    fi

# Final stage
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/python-packages

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    python3 \
    python3-pip \
    python3-dev \
    libgl1-mesa-glx \
    libglib2.0-0 \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Copy Python packages from builder
COPY --from=builder /python-packages /python-packages

# Create app directory and clone ComfyUI
WORKDIR /app
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /tmp/comfyui && \
    cp -r /tmp/comfyui/. . && \
    rm -rf /tmp/comfyui

# Copy settings file
COPY settings.yaml /app/config.yaml

# Install ComfyUI requirements
RUN pip3 install --no-cache-dir -r requirements.txt \
    && rm -rf ~/.cache/pip/*

# Create directories for models and outputs
RUN mkdir -p \
    models/checkpoints \
    models/clip \
    models/controlnet \
    models/vae \
    models/loras \
    input \
    output

# Expose port
EXPOSE 8188

# Copy and set entrypoint script
COPY data/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
