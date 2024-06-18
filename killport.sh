
#!/bin/bash

# Check if the port number is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <port>"
  exit 1
fi

PORT=$1

# Find the PID of the process using the specified port
PID=$(lsof -t -i :$PORT)

# Check if a process is using the specified port
if [ -z "$PID" ]; then
  echo "No process found using port $PORT"
  exit 0
fi

# Kill the process
kill -9 $PID

# Verify if the process was killed
if [ $? -eq 0 ]; then
  echo "Process using port $PORT (PID: $PID) has been killed."
else
  echo "Failed to kill the process using port $PORT (PID: $PID)."
fi
