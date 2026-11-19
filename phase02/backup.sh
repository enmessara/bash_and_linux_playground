
#!/usr/bin/env bash
#Colors
red='\033[0;91m'
green='\033[0;32m'
nc='\033[0m'

# Getting the source directory
read -rp "Enter source directory (full path): " src_dir

# Checking if the input is empty
if [[ -z "$src_dir" ]]; then
    echo -e "${red}Source directory cannot be empty!${nc}"
    exit 1
fi

# Step 3: Check whether source is a directory
if [[ ! -d "$src_dir" ]]; then
    echo -e "${red}The provided path is not a valid directory.${nc}"
    exit 1
fi

# Step 4: Remove trailing slash
src_dir="${src_dir%/}"

# Step 5: Generate timestamp
printf -v timestamp '%(%Y-%m-%d_%H-%M-%S)T' -1

# Step 6: Define backup directory
backup_dir="backup_${timestamp}"

# Step 7: Refuse to overwrite existing backup
if [[ -e "$backup_dir" ]]; then
    echo -e "${red}Backup already exists. Refusing to overwrite.${nc}"
    exit 1
fi

# Step 8: Create backup directory
if ! mkdir "$backup_dir"; then
    echo -e "${red}Failed to create backup directory.${nc}"
    exit 1
fi

# Step 9: Copy source directory
if cp -r "$src_dir" "$backup_dir/"; then
    echo -e "${green}Backup completed successfully!${nc}"
    echo "Backup location: $backup_dir"
else
    echo -e "${red}Backup failed!${nc}"
    exit 1
fi

