#!/bin/bash

# Loop through all files in the current directory
for file in *; do
  # Check if the file is a regular file and if it is a bash script
  if [[ -f "$file" && "$file" == *.sh ]]; then
    # Set the execute permission
    chmod +x "$file"
    echo "Set execute permission on $file"
  fi
done
