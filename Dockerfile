# Step 1
FROM nvidia/cuda:11.7.1-cudnn8-runtime-ubuntu20.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

RUN rm /etc/apt/sources.list.d/cuda.list && \
    apt-get -qq update && \
    apt-get -qqy install python3-pip git cmake python3.8-venv

RUN python3 -m pip install -U pip wheel build

COPY requirements-build.txt /app/requirements-build.txt

RUN python3 -m venv /app/venv

# Torch
RUN /app/venv/bin/pip install torch torchvision torchaudio

# Paddle with cuda 11.7
RUN /app/venv/bin/pip install \
    --trusted-host=www.paddlepaddle.org.cn \
    paddlepaddle-gpu==2.4.2.post117 \
    -f https://www.paddlepaddle.org.cn/whl/linux/mkl/avx/stable.html

RUN /app/venv/bin/pip install -r requirements-build.txt

# Workaround: uninstall typing at the end
RUN /app/venv/bin/pip uninstall -y typing

# Step 2
FROM nvidia/cuda:11.7.1-cudnn8-runtime-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive
ARG PIP_DISABLE_PIP_VERSION_CHECK=1
ARG PIP_NO_CACHE_DIR=1

WORKDIR /app

RUN rm /etc/apt/sources.list.d/cuda.list && \
    apt-get -qq update && \
    apt-get -qqy install python3-pip curl libgl1 libglib2.0-0 python3.8-venv && \
    rm -rf /var/lib/apt/lists/* && \
    cd /usr/lib/x86_64-linux-gnu && \
    test ! -f libcudnn.so && \
    ln -s libcudnn.so.8.5.0 libcudnn.so && \
    test ! -f libcublas.so && \
    ln -s /usr/local/cuda-11.7/targets/x86_64-linux/lib/libcublas.so.11.10.3.66 libcublas.so

# COPY . /app/
COPY --from=builder /app/venv /app/venv

CMD exec /bin/sh -c "trap : TERM INT; sleep 9999999999d & wait"
