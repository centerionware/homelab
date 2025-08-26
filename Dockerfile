FROM nvidia/cuda:12.1.1-devel-ubuntu20.04
ENV CUDA_HOME=/usr/local/cuda-12.1
ENV DEBIAN_FRONTEND=noninteractive 
ENV TZ=Etc/UTC
RUN apt update && apt install -y bash git gcc python3-dev python3-pip python3-venv python3-pyaudio build-essential wget curl cmake ninja-build  && rm  -rf /tmp/* && apt-get clean
RUN pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121

WORKDIR /workspace
RUN git clone https://github.com/vllm-project/vllm.git
WORKDIR /workspace/vllm

# Upgrade pip & basics
# RUN pip install --upgrade pip setuptools wheel packaging

# Tell vLLM to clean requirements to use our installed torch
RUN python3 use_existing_torch.py

# Install build requirements
RUN pip install -r requirements/build.txt

# Build and install vLLM from source
RUN pip install --no-build-isolation -e .

# Default command (can be overridden in k8s deployment)
CMD ["python3", "-m", "vllm.entrypoints.api_server"]
