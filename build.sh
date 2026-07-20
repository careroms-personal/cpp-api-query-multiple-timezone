#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

SRC_DIR="src"
THIRD_PARTY_DIR="third_party"
OUT="server"
STD="c++17"

CXX="${CXX:-}"
if [ -z "$CXX" ]; then
  if command -v g++ >/dev/null 2>&1; then
    CXX="g++"
  elif command -v clang++ >/dev/null 2>&1; then
    CXX="clang++"
  else
    echo "error: no C++ compiler found (looked for g++, clang++). Set \$CXX to override." >&2
    exit 1
  fi
fi

SOURCES=("$SRC_DIR"/*.cpp)

echo "Building $OUT with $CXX (-std=$STD)"
"$CXX" -std="$STD" -O2 -Wall -Wextra \
  -I "$THIRD_PARTY_DIR" \
  -pthread \
  -static-libgcc -static-libstdc++ \
  "${SOURCES[@]}" \
  -o "$OUT"

echo "Build complete: ./$OUT"
