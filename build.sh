#!/usr/bin/env sh
# Usage: ./build.sh [static|shared]      (default: static)
set -e
MODE=$(echo "${1:-static}" | tr a-z A-Z)
cmake -S . -B build -DRUST_LINK_MODE="$MODE" -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
echo "--- running ---"
./build/app
