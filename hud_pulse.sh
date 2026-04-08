#!/bin/bash

STATE_FILE="/tmp/yazi_hud_state"

if [ ! -f "$STATE_FILE" ]; then
  echo "1" > "$STATE_FILE"
fi

STATE=$(cat "$STATE_FILE")

if [ "$STATE" = "1" ]; then
  COLOR="#ff9e57"
  echo "2" > "$STATE_FILE"
else
  COLOR="#b026ff"
  echo "1" > "$STATE_FILE"
fi

echo "$COLOR"
