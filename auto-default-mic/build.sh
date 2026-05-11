#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
swiftc -O AutoDefaultMic.swift -o auto-default-mic \
    -framework CoreAudio -framework Foundation
echo "Built: $(pwd)/auto-default-mic"
