#!/bin/bash

if [ -f "fifo_rshd.config" ]; then
    source "fifo_rshd.config"
else
    echo "Error: Missing configuration file('rshd.config')"
    exit 1
fi

cleanup() {
    echo -e "\n[MASTER] Oprire server..."
    pkill -P $$ # Opreste procesele copil (sclavii)
    rm -f "$MASTER_FIFO"
    rm -rf "$SLAVE_DIR"
    exit 0
}
trap cleanup SIGINT SIGTERM

rm -f "$MASTER_FIFO"
mkdir -p "$SLAVE_DIR"
mkfifo "$MASTER_FIFO"

echo "Waiting requests from $MASTER_FIFO"

rm -f "$SLAVE_DIR"/slave_*

for i in $(seq 1 $N_SLAVES); do
    ./slave.sh "$i" & #"$SLAVE_DIR" &
    echo "Slave $i initialized (PID $!)"
done

rr_counter=0

while true; do

    read LINE < "$MASTER_FIFO"
    if [[ "$LINE" != *"BEGIN-REQ"* ]] || [[ "$LINE" != *"END-REQ"* ]]; then
            continue
    fi

    CLIENT_PID=$(echo "$LINE" | sed -E 's/.*\[([0-9]+):.*/\1/')
    COMMAND=$(echo "$LINE" | sed -E 's/^BEGIN-REQ \[[0-9]+: (.*)\] END-REQ$/\1/')
    SLAVE_ID=$(( rr_counter % N_SLAVES + 1 ))
    SLAVE_FIFO="$SLAVE_DIR/slave_$SLAVE_ID"

    echo "[master] Request from $CLIENT_PID: '$COMMAND'"
    echo "[master] Sent to Slave $SLAVE_ID --> $SLAVE_FIFO"
    REPLY_FIFO="/tmp/server-reply-$CLIENT_PID"
    echo "$REPLY_FIFO $COMMAND" > "$SLAVE_FIFO"
    rr_counter=$((rr_counter + 1))

done