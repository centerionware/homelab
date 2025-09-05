FROM pytorch/pytorch:2.8.0-cuda12.8-cudnn9-devel
# Run a quick test so can tell at build time if it's at all working. I don't expect cuda.is_available() to be available unless running on a runner with it setup.
# My current Kubernetes build environment doesn't change the default runtime class so no matter what as is on my cluster it won't have gpu access while building.
# RUN python3 -c "import torch; print(torch.__version__); print(torch.cuda.is_available()); print(torch.version.cuda)"

# RUN pip install torch==2.8.0 torchvision --index-url https://download.pytorch.org/whl/cu121
WORKDIR /workspace
RUN apt update && apt install git -y && git clone https://github.com/vllm-project/vllm.git
WORKDIR /workspace/vllm
RUN git checkout v0.10.1.1
ENV TORCH_CUDA_ARCH_LIST="6.0;6.1;7.0;7.5;8.0;8.6;8.9;9.0+PTX;12.0"
RUN pip install ninja 
# && pip install -v --no-build-isolation -U --no-deps git+https://github.com/facebookresearch/xformers.git@main#egg=xformers
# Upgrade pip & basics
# RUN pip install --upgrade pip setuptools wheel packaging

# Tell vLLM to clean requirements to use our installed torch
RUN python3 use_existing_torch.py

# Install build requirements
RUN pip install -r requirements/build.txt && pip install --upgrade transformers && sed -i 's/< 7/< 6/g' /opt/conda/lib/python3.11/site-packages/torch/_inductor/scheduler.py && sed -i 's/7.0;/6.0;6.1;7.0;/g' /workspace/vllm/CMakeLists.txt

# Build and install vLLM from source
RUN pip install --no-build-isolation -e .

# Default command (can be overridden in k8s deployment)
CMD ["python3", "-m", "vllm.entrypoints.api_server"]
