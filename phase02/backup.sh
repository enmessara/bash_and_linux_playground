#!/usr/bin/env bash

read -rp "Enter source directory(full path): " src_dir
if [ -z $src_dir ]; then
    echo "Source directory cannot be empty!"
    exit 1
fi

