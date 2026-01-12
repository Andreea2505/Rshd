#!/bin/bash

if [ -f "fifo_rshd.config" ]; then
    source "fifo_rshd.config"
else
    echo "Error: Missing configuration file('rshd.config')"
    exit 1
fi

if [ $# -eq 0 ]; then
    echo "Accepted format: $0 <shell commands>"
    exit 1
fi

cleanup() {
    rm -f "$REPLY_FIFO"
    echo -e "\n[Client] Shutting down..."
    exit
}
trap cleanup SIGINT SIGTERM EXIT

CLIENT_PID="$$"
REPLY_FIFO="/tmp/server-reply-$CLIENT_PID"
COMMAND="$@"
mkfifo "$REPLY_FIFO"

if [ ! -p "$MASTER_FIFO" ]; then
    echo "Error: Master FIFO not found. Start master server first."
    rm "$REPLY_FIFO"
    exit 1
fi

echo "Client $CLIENT_PID --- FIFO: $REPLY_FIFO"
REQUEST_LINE="BEGIN-REQ [$CLIENT_PID: $COMMAND] END-REQ"
echo "$REQUEST_LINE" > "$MASTER_FIFO"
echo "Client $CLIENT_PID: Request sent. Waiting response..."

RESULT=$(cat "$REPLY_FIFO")

echo -e "\n--- RESULT OF [$COMMAND] ---"
echo "$RESULT"
echo "*-------------------------------*"

rm "$REPLY_FIFO"
echo "Client $CLIENT_PID: FIFO deleted."