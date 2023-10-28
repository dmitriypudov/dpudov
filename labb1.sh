#!/bin/bash -e

cleanup() {
  [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
  exit
}

trap cleanup EXIT INT TERM

if [ -z "$1" ]; then
  echo "Error: No source file specified"
  exit 1
fi

SOURCE_FILE="$1"
TEMP_DIR=$(mktemp -d)
OUTPUT_NAME=""

if ! [ -f "$SOURCE_FILE" ] || ! [ -r "$SOURCE_FILE" ]; then
  echo "Error: Source file does not exist or is not readable"
  exit 1
fi


while IFS= read -r line; do
  if echo "$line" | grep -qE '^\s*//&Output:'; then
    OUTPUT_NAME=$(echo "$line" | sed -e 's/^\s*\/\/&Output:\s*//')
    break
  fi
done < "$SOURCE_FILE"

if [ -z "$OUTPUT_NAME" ]; then
  echo "Error: Output file name not found in the source file"
  exit 1
fi


if echo "$SOURCE_FILE" | grep -qE '\.c$|\.cpp$'; then
  g++ "$SOURCE_FILE" -o "$TEMP_DIR/$OUTPUT_NAME" -lstdc++
elif echo "$SOURCE_FILE" | grep -qE '\.tex$'; then
  pdflatex -output-directory "$TEMP_DIR" "$SOURCE_FILE" >/dev/null
  mv "$TEMP_DIR/$(basename "$SOURCE_FILE" .tex).pdf" "$TEMP_DIR/$OUTPUT_NAME"
else
  echo "Error: Unsupported file extension"
  exit 1
fi


mv "$TEMP_DIR/$OUTPUT_NAME" "$(dirname "$SOURCE_FILE")/"
echo "Build successful. Output file: $(dirname "$SOURCE_FILE")/$OUTPUT_NAME"
