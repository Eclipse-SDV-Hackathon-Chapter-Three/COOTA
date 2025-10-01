#!/bin/bash

SAFETY_FILE=".safety_state"

INTERVAL=5

STATE="SAFE"

# Infinite loop
while true; do
    # Write the current state to the file
    echo "$STATE" > "$SAFETY_FILE"

    # Alternate the state
    if [ "$STATE" == "SAFE" ]; then
        STATE="DRIVING"
    else
        STATE="SAFE"
    fi

    # Wait for the specified interval
    sleep "$INTERVAL"
done