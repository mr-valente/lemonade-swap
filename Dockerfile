FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Minimal tools to download and extract the llama.cpp ROCm build
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        unzip \
        gcc \
        libatomic1 \
        # For huggingface-hub
        python3 \
        python3-pip \
        # For llama-swap
        tar \
    && rm -rf /var/lib/apt/lists/*

# Install huggingface-hub for model downloads
RUN pip3 install --no-cache-dir huggingface-hub[cli] --break-system-packages

# Where we'll put the llama.cpp ROCm binaries and llama-swap
WORKDIR /opt/llama

# Install llama-swap binary from GitHub releases
ARG LLAMA_SWAP_VERSION
RUN curl -L "https://github.com/mostlygeek/llama-swap/releases/download/v${LLAMA_SWAP_VERSION}/llama-swap_${LLAMA_SWAP_VERSION}_linux_amd64.tar.gz" -o /tmp/llama-swap.tar.gz && \
    tar -xzf /tmp/llama-swap.tar.gz -C /opt/llama && \
    rm /tmp/llama-swap.tar.gz && \
    chmod +x /opt/llama/llama-swap

# Download and extract the gfx1151 Ubuntu ROCm build
# (b1111 release, ROCm 7 built-in; no extra ROCm install needed) 
ARG LLAMACPP_RELEASE
ARG LLAMACPP_GFX

RUN set -eux; \
    curl -L "https://github.com/lemonade-sdk/llamacpp-rocm/releases/download/${LLAMACPP_RELEASE}/llama-${LLAMACPP_RELEASE}-ubuntu-rocm-${LLAMACPP_GFX}-x64.zip" -o /tmp/llama.zip; \
    unzip /tmp/llama.zip; \
    rm /tmp/llama.zip; \
    # Move contents up if they were extracted into a subdirectory
    if [ -d llama-${LLAMACPP_RELEASE}-ubuntu-rocm-${LLAMACPP_GFX}-x64 ]; then \
        mv llama-${LLAMACPP_RELEASE}-ubuntu-rocm-${LLAMACPP_GFX}-x64/* . && \
        rmdir llama-${LLAMACPP_RELEASE}-ubuntu-rocm-${LLAMACPP_GFX}-x64; \
    fi; \
    chmod +x llama-server

# Add llama binaries to PATH
ENV PATH="/opt/llama:${PATH}"

# Configure llama-server defaults
# ENV LLAMA_ARG_HOST=0.0.0.0
# ENV LLAMA_ARG_PORT=8000

# Configure Hugging Face Hub
# HF_HOME sets the base directory for all HF data (token, cache, models)
# HF_HUB_CACHE sets where models are downloaded
# ENV HF_HOME=/huggingface
# ENV HF_HUB_CACHE=/huggingface/hub

# Default llama-swap config location (can be overridden)
# ENV LLAMA_SWAP_CONFIG=/config/config.yaml
# ENV LLAMA_SWAP_LISTEN=0.0.0.0:8080

# llama-swap listens on port 8080 by default
# EXPOSE 8080

WORKDIR /

CMD ["llama-swap", "--config", "/config/config.yaml", "--listen", "0.0.0.0:8080"]


