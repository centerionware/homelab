FROM ghcr.io/centerionware/jarvis@sha256:0857d83eaac21ef59986c2f5c9d58451507976ef00cab6323cace7c6d99bb7c1 

ENV DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC
RUN apt update && apt install -y bash git gcc python3-dev python3-pip python3-venv python3-pyaudio build-essential wget curl cmake ninja-build  && rm  -rf /tmp/* && apt-get clean

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