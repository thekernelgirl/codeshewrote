# Get the filename and extension
filename=$(basename -- "$1")
extension="${filename##*.}"
filename="${filename%.*}"

# Copy file contents to clipboard
pbcopy < "$1"

# Generate new filename with "-rs" suffix
new_filename="${filename}-rs.${extension}"

# Create a new file with the copied content
touch "$new_filename"

echo "File copied to clipboard and saved as $new_filename"

