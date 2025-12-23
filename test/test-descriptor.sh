#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NUMS_KEY="0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0"

HOT="tpubD6NzVbkrYhZ4YRta2zJKR8cGe1nq5Se5g8xyZxWQxjV7qo3Z1dCoWH9kH6SHrwUpBAkLTnX2UjsFvdcGaVbL9DJBSSTXobHxPPH1kN6H9We"
COLD="tpubD6NzVbkrYhZ4XUf4r8Q4f4fbQ3qykF5NCz7YsYsJhBKt3vnDnNQfX6BxPTsCkXbkNvVKgfH7C9ZwTe74MkRUYw35vjpsXadB1iKsFcEYJIh"
RECOV="tpubD6NzVbkrYhZ4YF1vGjufH6G6DqJziWBGSAdoo6gWQBaUXpBoBPuiGNsq4CPGK8PvX9nuSUXGKmzME2YkdEYY5EYXPLkZX31vT7xGTFeoDyC"

DESC=$(node "$ROOT/src/descriptors.js" --hot "$HOT" --cold "$COLD" --recovery "$RECOV" --network signet --range "[0,1]" --with-checksum)

echo "Descriptor: $DESC"

if [[ "$DESC" == tr(${NUMS_KEY}*) ]]; then
  :
else
  echo "NUMS internal key missing"
  exit 1
fi

if ! echo "$DESC" | grep -q "multi(2"; then
  echo "Expected multi(2) script tree"
  exit 1
fi

if command -v bitcoin-cli >/dev/null 2>&1; then
  echo "Validating descriptor via bitcoin-cli --signet ..."
  bitcoin-cli --signet getdescriptorinfo "$DESC" >/dev/null
else
  echo "bitcoin-cli not found; skipping on-chain validation."
fi
