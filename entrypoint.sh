#!/usr/bin/env bash
set -e

if [ -z "${MODEL}" ]; then
  echo "ERROR: MODEL environment variable is not set."
  echo "Please set MODEL to the path of your GGUF model inside the container."
  echo "Example: MODEL=/models/your-model.gguf"
  exit 1
fi

# cd /opt/llama
echo "Starting llama-server with model: ${MODEL}"
exec llama-server -m "${MODEL}" # --port 8000 --host 0.0.0.0 # -ngl 99
# exec sleep infinity
