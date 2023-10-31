# Step 1
FROM nvidia/cuda:11.7.1-cudnn8-runtime-ubuntu20.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/app/venv/bin:${PATH}"

WORKDIR /app

COPY zscaler-*.crt /usr/local/share/ca-certificates
RUN update-ca-certificates

RUN sed -i 's/deb h/deb [trusted=yes] h/g' /etc/apt/sources.list.d/cuda.list && \
    apt -qq update && \
    apt -qqy install python3-pip git cmake python3.8-venv

RUN python3 -m pip install -U pip wheel build

COPY requirements-build.txt /app/requirements-build.txt

RUN python3 -m venv /app/venv

# Torch
RUN /app/venv/bin/pip install torch==2.0.0 torchvision==0.15.1 torchaudio==2.0.1 torchtext

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
ENV PATH="/app/venv/bin:${PATH}"
ARG PIP_DISABLE_PIP_VERSION_CHECK=1
ARG PIP_NO_CACHE_DIR=1

WORKDIR /app

# Add zscaler
COPY zscaler-*.crt /usr/local/share/ca-certificates

# cuda-profiler-api 11.7 is not present, using 11.8 and symlinking
RUN update-ca-certificates && \
    sed -i 's/deb h/deb [trusted=yes] h/g' /etc/apt/sources.list.d/cuda.list && \
    apt -qq update && \
    apt -qqy install \
             python3-pip \
             curl \
             libgl1 \
             libglib2.0-0 \
             python3.8-venv \
             cuda-nvcc-11-7 \
             libcublas-dev-11-7 \
             libcusolver-dev-11-7 \
             cuda-profiler-api-11-8 \
             libcusparse-dev-11-7 && \
    rm -rf /var/lib/apt/lists/* && \
    cd /usr/lib/x86_64-linux-gnu && \
    test ! -f libcudnn.so && \
    ln -s libcudnn.so.8.5.0 libcudnn.so && \
    test ! -f libcublas.so && \
    ln -s /usr/local/cuda-11.7/targets/x86_64-linux/lib/libcublas.so.11.10.3.66 libcublas.so \
    ln -s /usr/local/cuda-11.8/targets/x86_64-linux/include/cuda_profiler_api.h cuda_profiler_api.h /usr/local/cuda-11.7/targets/x86_64-linux/include/cuda_profiler_api.h cuda_profiler_api.h

# COPY . /app/
COPY --from=builder /app/venv /app/venv

CMD exec /bin/sh -c "trap : TERM INT; sleep 9999999999d & wait"
