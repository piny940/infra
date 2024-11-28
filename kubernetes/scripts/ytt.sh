#!/bin/bash

for file in $(find apps -type f -name *.ytt.yml -or -name *.ytt.yaml); do
  echo "Processing $file"

  # apps/.../xxx.ytt.yml -> apps/.../gen/
  dir=$(echo "$file" | sed 's|\(apps/.*/\)[^/]*$|\1gen/|')
  mkdir -p "$dir"

  # apps/.../xxx.ytt.yml -> apps/.../gen/xxx.yml
  out=$(echo "$file" | sed 's|\(apps/.*/\)\([^/]*\)\.ytt\..*$|\1gen/\2.yaml|')
  
  ytt -f "$file" -f components/ytt/ > "$out"
done