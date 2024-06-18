# bash-util


Install script:
```
#!/bin/bash

# Define the target directory
TARGET_DIR="$HOME/scripts"

# Create the target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Copy all .sh files to the target directory
cp *.sh "$TARGET_DIR"

# Update the PATH in .zprofile or .bashrc
if [ -f "$HOME/.zprofile" ]; then
    PROFILE_FILE="$HOME/.zprofile"
elif [ -f "$HOME/.bashrc" ]; then
    PROFILE_FILE="$HOME/.bashrc"
else
    echo "Neither .zprofile nor .bashrc found. Please add $TARGET_DIR to your PATH manually."
    exit 1
fi

# Add the target directory to the PATH if it's not already there
if ! grep -q "export PATH=\"$TARGET_DIR:\$PATH\"" "$PROFILE_FILE"; then
    echo "export PATH=\"$TARGET_DIR:\$PATH\"" >> "$PROFILE_FILE"
    echo "PATH updated in $PROFILE_FILE. Please restart your terminal or run 'source $PROFILE_FILE' to apply the changes."
else
    echo "PATH already includes $TARGET_DIR in $PROFILE_FILE."
fi
```
