FROM ghcr.io/centerionware/jarvis:python3.9-cuda-torch-torchvision-pyaudio

ENV DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC
RUN apt update && apt install -y bash git gcc python3-dev python3-pip python3-venv python3-pyaudio build-essential wget curl cmake ninja-build  && rm  -rf /tmp/* && apt-get clean

RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin \
    mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600 \
    wget https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda-repo-ubuntu2004-11-8-local_11.8.0-520.61.05-1_amd64.deb \
    dpkg -i cuda-repo-ubuntu2004-11-8-local_11.8.0-520.61.05-1_amd64.deb \
    cp /var/cuda-repo-ubuntu2004-11-8-local/cuda-*-keyring.gpg /usr/share/keyrings/ \
    apt-get update  \
    apt-get -y install cuda

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