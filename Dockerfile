FROM python:3.10-slim
run apt update && apt-cache search linux-headers
RUN apt update && apt install -y bash git gcc python3-pyaudio && rm  -rf /tmp/* && apt-get clean
RUN pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 
