#!/bin/bash

# Function to detect GPU vendor
detect_gpu() {
    # Check for NVIDIA GPUs
    if lspci | grep -i nvidia > /dev/null; then
        echo "NVIDIA"
        return
    fi

    # Check for AMD GPUs
    if lspci | grep -i amd > /dev/null; then
        echo "AMD"
        return
    fi

    # No GPU found
    echo "CPU"
}

# Output the detected GPU vendor
detect_gpu
