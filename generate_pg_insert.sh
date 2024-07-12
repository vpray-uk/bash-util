#!/bin/bash
# Generates SQL insert commands using pg_dump given a postgresql url. The script generate INSERTs using the order of the table relationship dependencies.

# Check if a PostgreSQL URL was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <postgresql-url>"
  exit 1
fi

# Database connection details from the first argument
DB_URL="$1"

# Check if pg_dump is installed
if ! command -v pg_dump &> /dev/null; then
  echo "pg_dump could not be found. Please install PostgreSQL client tools."
  exit 1
fi

# Extract database credentials from the URL using sed
USER=$(echo "$DB_URL" | sed -n 's|.*//\([^:]*\):.*|\1|p')
PASSWORD=$(echo "$DB_URL" | sed -n 's|.*:\([^@]*\)@.*|\1|p')
HOST=$(echo "$DB_URL" | sed -n 's|.*@\([^:]*\):.*|\1|p')
PORT=$(echo "$DB_URL" | sed -n 's|.*:\([0-9]*\)/.*|\1|p')
DB_NAME=$(echo "$DB_URL" | sed -n 's|.*/\([^?]*\)|\1|p')

# Export the password to avoid prompt
export PGPASSWORD="$PASSWORD"

# Get table dependencies
echo "Fetching table dependencies..."
DEPENDENCIES=$(psql "$DB_URL" -c "
SELECT 
  tc.table_name AS child_table,
  ccu.table_name AS parent_table
FROM 
  information_schema.table_constraints AS tc 
  JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
  JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE constraint_type = 'FOREIGN KEY';
" -t -A)

# Get all user tables in the public schema
echo "Fetching user table list..."
USER_TABLES=$(psql "$DB_URL" -c "
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public' AND tablename NOT LIKE 'pg_%' AND tablename NOT LIKE 'sql_%';
" -t -A)

# Function to topologically sort the tables based on dependencies
topological_sort() {
  local graph="$1"
  local sorted=()
  local visited=()

  visit() {
    local table="$1"
    for v in "${visited[@]}"; do
      if [ "$v" == "$table" ]; then
        return
      fi
    done
    visited+=("$table")
    for dep in $(echo "$graph" | grep "^$table " | cut -d' ' -f2); do
      visit "$dep"
    done
    sorted+=("$table")
  }

  for table in $(echo "$graph" | cut -d' ' -f1 | sort -u); do
    visit "$table"
  done

  echo "${sorted[@]}"
}

# Create a dependency graph as a space-separated string
graph=""
while IFS= read -r line; do
  child_table=$(echo "$line" | cut -d '|' -f 1 | xargs)
  parent_table=$(echo "$line" | cut -d '|' -f 2 | xargs)
  graph+="$child_table $parent_table"$'\n'
done <<< "$DEPENDENCIES"

# Topologically sort the tables
sorted_tables=$(topological_sort "$graph")

# Output file for the insert commands
OUTPUT_FILE="inserts.sql"
TEMP_FILE=$(mktemp)

# Clear the output file if it exists
> "$OUTPUT_FILE"

# Function to generate insert commands for a table
generate_inserts() {
  local table="$1"
  if echo "$USER_TABLES" | grep -w "$table" > /dev/null; then
    echo "-- Inserts for table $table --" >> "$TEMP_FILE"
    echo "Generating inserts for table $table..."
    pg_dump --username="$USER" --host="$HOST" --port="$PORT" --dbname="$DB_NAME" --data-only --inserts --column-inserts --no-comments --no-owner --table="\"$table\"" >> "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
  else
    echo "Skipping non-existent table $table..."
  fi
}

# Generate insert commands for sorted tables
for table in $sorted_tables; do
  generate_inserts "$table"
done

# Remove the unwanted SET commands
echo "Cleaning up the output file..."
sed '/^SET /d' "$TEMP_FILE" > "$OUTPUT_FILE"

# Remove the temporary file
rm "$TEMP_FILE"

# Unset the password variable for security reasons
unset PGPASSWORD

echo "Insert commands have been saved to $OUTPUT_FILE"
