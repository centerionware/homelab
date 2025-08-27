FROM nvidia/cuda:12.2.2-devel-ubuntu22.04
ENV CUDA_HOME=/usr/local/cuda-12.2
ENV DEBIAN_FRONTEND=noninteractive 
ENV TZ=Etc/UTC
ENV PATH=$CUDA_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

RUN apt update && apt install -y bash git gcc python3-dev python3-pip python3-venv python3-pyaudio build-essential wget curl cmake ninja-build  && rm  -rf /tmp/* && apt-get clean
RUN apt-get update && apt-get install -y \
    software-properties-common \
    libopenblas-dev libblas-dev libeigen3-dev \
    libssl-dev zlib1g-dev \
    python3-setuptools python3-wheel \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
RUN git clone --branch v2.8.0 --recursive https://github.com/pytorch/pytorch.git
WORKDIR /workspace/pytorch

RUN pip install -r requirements.txt
RUN pip install typing_extensions future six requests dataclasses
# Is the above needed? shouldn't everything required be in requirements?
ENV CMAKE_PREFIX_PATH="$(dirname $(which python3))/../" \
    USE_CUDA=1 \
    USE_CUDNN=1 \
    USE_MKLDNN=0 \
    USE_NCCL=1 \
    MAX_JOBS=8

RUN python3 setup.py install

# Run a quick test so can tell at build time if it's at all working. I don't expect cuda.is_available() to be available unless running on a runner with it setup.
# My current Kubernetes build environment doesn't change the default runtime class so no matter what as is on my cluster it won't have gpu access while building.
RUN python3 -c "import torch; print(torch.__version__); print(torch.cuda.is_available()); print(torch.version.cuda)"

# RUN pip install torch==2.8.0 torchvision --index-url https://download.pytorch.org/whl/cu121
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
