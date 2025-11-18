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
        # For Homebrew and llama-swap
        build-essential \
        procps \
        file \
        git \
    && rm -rf /var/lib/apt/lists/*

# Install huggingface-hub for model downloads
RUN pip3 install --no-cache-dir huggingface-hub[cli] --break-system-packages

# Create a non-root user for Homebrew installation
RUN useradd -m -s /bin/bash linuxbrew && \
    echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install Homebrew as linuxbrew user (non-interactive)
USER linuxbrew
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/null

# Install llama-swap
RUN /home/linuxbrew/.linuxbrew/bin/brew tap mostlygeek/llama-swap && \
    /home/linuxbrew/.linuxbrew/bin/brew install llama-swap

# Switch back to root for the rest of the build
USER root

# Add Homebrew to PATH
ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"

# Where we'll put the llama.cpp ROCm binaries
WORKDIR /opt/llama

# Download and extract the gfx1151 Ubuntu ROCm build
# (b1111 release, ROCm 7 built-in; no extra ROCm install needed) 
ARG LLAMA_ZIP_URL="https://github.com/lemonade-sdk/llamacpp-rocm/releases/download/b1111/llama-b1111-ubuntu-rocm-gfx1151-x64.zip"

RUN set -eux; \
    curl -L "$LLAMA_ZIP_URL" -o /tmp/llama.zip; \
    unzip /tmp/llama.zip; \
    rm /tmp/llama.zip; \
    # Move contents up if they were extracted into a subdirectory
    if [ -d llama-b1111-ubuntu-rocm-gfx1151-x64 ]; then \
        mv llama-b1111-ubuntu-rocm-gfx1151-x64/* . && \
        rmdir llama-b1111-ubuntu-rocm-gfx1151-x64; \
    fi; \
    chmod +x llama-server

# Add llama binaries to PATH
ENV PATH="/opt/llama:${PATH}"

# Configure llama-server defaults
ENV LLAMA_ARG_HOST=0.0.0.0
ENV LLAMA_ARG_PORT=8000

# Configure Hugging Face Hub
# HF_HOME sets the base directory for all HF data (token, cache, models)
# HF_HUB_CACHE sets where models are downloaded
ENV HF_HOME=/huggingface
ENV HF_HUB_CACHE=/huggingface/hub

# Default llama-swap config location (can be overridden)
ENV LLAMA_SWAP_CONFIG=/config/config.yaml
ENV LLAMA_SWAP_LISTEN=0.0.0.0:8080

# Simple entrypoint: require MODEL env var and run the quick smoketest command
# from the README:
#   llama-server -m YOUR_GGUF_MODEL_PATH -ngl 99 
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

# llama-swap listens on port 8080 by default
EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]


