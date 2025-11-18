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
    && rm -rf /var/lib/apt/lists/*

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

# Simple entrypoint: require MODEL env var and run the quick smoketest command
# from the README:
#   llama-server -m YOUR_GGUF_MODEL_PATH -ngl 99 
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

# llama-server defaults to port 8080 in llama.cpp, so we expose it
# EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]
