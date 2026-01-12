#!/bin/bash

source fifo_rshd.config
SLAVE_ID="$1"
#SLAVE_DIR="$2"

MY_FIFO="$SLAVE_DIR/slave_$SLAVE_ID"
if [ -p "$MY_FIFO" ]; then
    rm "$MY_FIFO"
fi
mkfifo "$MY_FIFO"
echo "Slave $SLAVE_ID initialized. Waiting commands from $MY_FIFO"

while true; do

    read -r REPLY_FIFO COMMAND < "$MY_FIFO"
    if [ -z "$COMMAND" ] || [ -z "$REPLY_FIFO" ]; then
        continue
    fi

    echo "[slave] Slave $SLAVE_ID running command: '$COMMAND'"
    echo "[slave] Slave $SLAVE_ID: output sent to $REPLY_FIFO"
    
    if [ -p "$REPLY_FIFO" ]; then
            if [[ "$COMMAND" == *"rm "* ]] || [[ "$COMMAND" == *"mv "* ]]; then
                echo "Error: Forbidden" > "$REPLY_FIFO" 2>&1
            else
                eval "$COMMAND" > "$REPLY_FIFO" 2>&1
            fi
    else
            echo "[slave] Slave $SLAVE_ID Error: Client FIFO not found ($REPLY_FIFO)"
    fi

done