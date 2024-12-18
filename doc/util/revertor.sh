#!/bin/sh

TMP=$(mktemp -d)

# for c in f8d7bd6 c51737d 4d8528a a89b82c
for c in c51737d 4d8528a a89b82c
do
  git diff "$c" -- 'src/lib/terminal.lua' > "$TMP/$c.patch"
done

echo "$TMP"
ls "$TMP"
