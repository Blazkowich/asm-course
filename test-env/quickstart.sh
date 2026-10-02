#!/usr/bin/env bash
# test-env/quickstart.sh
# ერთი ბრძანებით: Docker-ის build + verify + tests.
# გამოყენება:  ./quickstart.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

IMAGE="asm-course"

echo "→ Docker image build..."
docker build -t "$IMAGE" "$SCRIPT_DIR"

echo
echo "→ verify.sh..."
docker run --rm -v "$PARENT_DIR:/work" -w /work/test-env "$IMAGE" bash verify.sh

echo
echo "→ run-tests.sh..."
docker run --rm -v "$PARENT_DIR:/work" -w /work/test-env "$IMAGE" bash run-tests.sh

echo
echo "→ ინტერაქტიული shell-ის გაშვება (გასვლა: exit)..."
docker run --rm -it -v "$PARENT_DIR:/work" -w /work "$IMAGE"