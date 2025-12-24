#!/bin/bash
# Quick balance check via mempool.space API (no sync needed)

ADDR=${1:-"tb1py4kh2gxusds4mk4yuxjl9m5dmazvjcnrfj6u8mn7mwd5wy90uhxqvmqrrc"}

echo "Checking: $ADDR"
DATA=$(curl -s "https://mempool.space/testnet/api/address/$ADDR")
FUNDED=$(echo "$DATA" | jq '.chain_stats.funded_txo_sum')
SPENT=$(echo "$DATA" | jq '.chain_stats.spent_txo_sum')
TX_COUNT=$(echo "$DATA" | jq '.chain_stats.tx_count')
BALANCE=$((FUNDED - SPENT))

echo "Balance: $BALANCE sats ($(echo "scale=8; $BALANCE / 100000000" | bc) tBTC)"
echo "Received: $FUNDED sats"
echo "Spent: $SPENT sats"
echo "Transactions: $TX_COUNT"

echo ""
echo "View on explorer: https://mempool.space/testnet/address/$ADDR"
