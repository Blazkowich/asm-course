#!/usr/bin/env bash
# test-env/quickstart.sh
# ერთი ბრძანებით: Docker-ის build + verify + tests.
# გამოყენება:  ./quickstart.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

IMAGE="asm-course"

echo "→ Docker image build..."
docker buildx build -t "$IMAGE" "$SCRIPT_DIR"

echo
echo "→ verify.sh..."
docker run --rm -v "$PARENT_DIR:/work" -w /work/test-env "$IMAGE" bash verify.sh

echo
echo "→ run-tests.sh (პროგრესი)..."
# შენიშვნა: დასაწყისში ყველა დავალება "დაუწერელია" — ეს ნორმალურია.
docker run --rm -v "$PARENT_DIR:/work" -w /work/test-env "$IMAGE" bash run-tests.sh --progress

echo
echo "→ დავალებების სია (solutions/-ში წერ):"
docker run --rm -v "$PARENT_DIR:/work" -w /work/test-env "$IMAGE" bash run-tests.sh --list

echo
echo "→ ინტერაქტიული shell-ის გაშვება (გასვლა: exit)..."
echo "   შიგნით: cd /work/test-env && ./run-tests.sh --guide w1d1_exit42"
docker run --rm -it -v "$PARENT_DIR:/work" -w /work "$IMAGE"