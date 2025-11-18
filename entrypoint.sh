#!/usr/bin/env bash
set -e

if [ -z "${LLAMA_SWAP_CONFIG}" ]; then
  echo "ERROR: LLAMA_SWAP_CONFIG environment variable is not set."
  echo "Please set LLAMA_SWAP_CONFIG to the path of your config.yaml inside the container."
  echo "Example: LLAMA_SWAP_CONFIG=/config/config.yaml"
  exit 1
fi

if [ ! -f "${LLAMA_SWAP_CONFIG}" ]; then
  echo "ERROR: Config file not found at: ${LLAMA_SWAP_CONFIG}"
  exit 1
fi

echo "Starting llama-swap with config: ${LLAMA_SWAP_CONFIG}"
echo "Listening on: ${LLAMA_SWAP_LISTEN}"
exec llama-swap --config "${LLAMA_SWAP_CONFIG}" --listen "${LLAMA_SWAP_LISTEN}"
