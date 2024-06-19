#!/bin/bash

# Check if the required connection URL is passed as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <postgresql_connection_url>"
    exit 1
fi

# Extract the connection details from the URL
connection_url=$1

# Parse the connection URL to extract components
proto=$(echo $connection_url | sed -n 's,^\([^:]*\)://.*,\1,p')
username=$(echo $connection_url | sed -n 's,^.*://\([^:]*\):.*,\1,p')
password=$(echo $connection_url | sed -n 's,^.*://[^:]*:\([^@]*\)@.*,\1,p')
host=$(echo $connection_url | sed -n 's,^.*://[^@]*@\(.*\):[0-9]*.*,\1,p')
port=$(echo $connection_url | sed -n 's,^.*://[^@]*@[^:]*:\([0-9]*\).*,\1,p')
dbname=$(echo $connection_url | sed -n 's,^.*://[^@]*@[^:]*:[0-9]*/\(.*\),\1,p')

# Check if all components are parsed
if [ -z "$username" ] || [ -z "$password" ] || [ -z "$host" ] || [ -z "$port" ] || [ -z "$dbname" ]; then
    echo "Error parsing the connection URL."
    exit 1
fi

# Export the password to avoid password prompt
export PGPASSWORD=$password

# Run pg_dump to generate the SQL dump
pg_dump -s -h $host -p $port -U $username -d $dbname -b -v -f "$dbname.dump"

# Unset the password environment variable
unset PGPASSWORD

echo "SQL dump has been generated and saved as $dbname.dump"
