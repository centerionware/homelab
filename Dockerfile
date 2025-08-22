# ============================================================
# Stage 1: Build vLLM from source with CUDA 11.8
# ============================================================
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04 AS builder

# System dependencies
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    wget \
    curl \
    cmake \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

# Create a working directory
WORKDIR /workspace

# Clone vLLM repo
RUN git clone https://github.com/vllm-project/vllm.git
WORKDIR /workspace/vllm

# Apply modifications for CUDA 11.8
# 1. Remove pyproject.toml to avoid enforcing torch/xformers
RUN rm -f pyproject.toml

# 2. Change setup.py to force CUDA 11.8
RUN sed -i 's/^MAIN_CUDA_VERSION.*/MAIN_CUDA_VERSION = "11.8"/' setup.py

# 3. Remove torch & xformers from requirements
RUN sed -i '/torch/d' requirements.txt && sed -i '/xformers/d' requirements.txt

# Install Python deps
RUN pip install --upgrade pip setuptools wheel packaging

# Install PyTorch for CUDA 11.8
RUN pip install torch==2.2.2+cu118 torchvision==0.17.2+cu118 torchaudio==2.2.2+cu118 \
    --index-url https://download.pytorch.org/whl/cu118

# Install xformers for CUDA 11.8
RUN pip install -U xformers --index-url https://download.pytorch.org/whl/cu118

# Install vLLM from source
RUN pip install -e .

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
