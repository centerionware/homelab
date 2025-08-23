FROM nvidia/cuda:11.8.0-devel-ubuntu22.04 AS builder

RUN apt-get update && apt-get install -y \
    git build-essential python3 python3-dev python3-pip python3-venv \
    wget curl cmake ninja-build \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
RUN git clone https://github.com/vllm-project/vllm.git
WORKDIR /workspace/vllm

# Upgrade pip & basics
RUN pip install --upgrade pip setuptools wheel packaging

# Install PyTorch stack (CUDA 11.8)
RUN pip install torch==2.7.1+cu118 torchvision xformers--extra-index-url https://download.pytorch.org/whl/cu118

# Install matching xformers
# RUN pip install xformers==0.0.31.post1 --index-url https://download.pytorch.org/whl/cu118

# Tell vLLM to clean requirements to use our installed torch
RUN python3 use_existing_torch.py

# Install build requirements
RUN pip install -r requirements/build.txt

# Build and install vLLM from source
RUN pip install --no-build-isolation -e .

# ============================================================
# Stage 2: Runtime Image
# ============================================================
FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04 AS runtime

# System deps
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy installed site-packages & vllm binaries from builder
COPY --from=builder /usr/local/lib/python3.10/dist-packages /usr/local/lib/python3.10/dist-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Optional: copy vllm repo (for scripts/configs)
COPY --from=builder /workspace/vllm /app/vllm

# Install packaging again (needed at runtime sometimes)
RUN pip install packaging

# Default command (can be overridden in k8s deployment)
CMD ["python3", "-m", "vllm.entrypoints.api_server"]
