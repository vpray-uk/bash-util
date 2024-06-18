
#!/bin/bash

# Check if exactly two arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source_db_url> <destination_db_url>"
    exit 1
fi

# Assign the input arguments to variables
SOURCE_DB_URL=$1
DEST_DB_URL=$2

# Temporary file to store the database dump
DUMP_FILE="db_dump.sql"

# Check if the dump file already exists
if [ -f $DUMP_FILE ]; then
    echo "Dump file already exists. Using the existing dump file."
else
    # Dump the source database to a file
    echo "Dumping data from source database..."
    pg_dump $SOURCE_DB_URL -F c -b -v -f $DUMP_FILE
    if [ $? -ne 0 ]; then
        echo "Failed to dump the source database."
        exit 1
    fi
fi

# Restore the dump to the destination database
echo "Restoring data to destination database..."
pg_restore -d $DEST_DB_URL -v $DUMP_FILE
if [ $? -ne 0 ]; then
    echo "Failed to restore the dump to the destination database."
    exit 1
fi

echo "Data has been successfully moved from the source database to the destination database."
