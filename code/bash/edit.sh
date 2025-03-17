#!/bin/bash

# Directory containing the files
DIRECTORY="/path/to/your/directory"

# Extension of files to search
OLD_EXTENSION="txt"

# New extension
NEW_EXTENSION="md"

# Value to find
OLD_VALUE="oldValue"

# New value to replace with
NEW_VALUE="newValue"

# Loop through all files with the specified old extension in the directory
for file in "$DIRECTORY"/*.$OLD_EXTENSION; do
  # Check if the file exists to avoid errors in case of no matching files
  if [ -f "$file" ]; then
    # Replace oldValue with newValue in the file content using sed
    sed -i '' "s/$OLD_VALUE/$NEW_VALUE/g" "$file"
    
    # Construct new file name by changing the extension
    new_file=$(echo "$file" | sed "s/\.$OLD_EXTENSION$/.$NEW_EXTENSION/")
    
    # Rename the file to change its extension
    mv "$file" "$new_file"
    
    echo "Processed and renamed: $new_file"
  fi
done

echo "All files processed."

