#!/bin/bash

# Check if a URL is passed as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 postgresql://<user>:<password>@<host>:<port>/<database>"
    exit 1
fi

# Extract the URL
url=$1

# Use regex to parse the URL
if [[ $url =~ postgresql://([^:]+):([^@]+)@([^:]+):([0-9]+)/([^/]+) ]]; then
    user="${BASH_REMATCH[1]}"
    password="${BASH_REMATCH[2]}"
    host="${BASH_REMATCH[3]}"
    port="${BASH_REMATCH[4]}"
    database="${BASH_REMATCH[5]}"
else
    echo "Invalid URL format"
    exit 1
fi

# Create the JSON object
json=$(cat <<EOF
{
    "database": "$database",
    "host": "$host",
    "user": "$user",
    "password": "$password",
    "port": "$port"
}
EOF
)

# Print the JSON object
echo "$json"
