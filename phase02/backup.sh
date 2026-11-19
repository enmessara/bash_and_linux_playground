
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

# Check if source is a non-directory
if [[ ! -d "$src_dir" ]]; then
    echo -e "${red}The provided path is not a valid directory.${nc}"
    exit 1
fi

# Remove trailing slash
src_dir="${src_dir%/}"

# Getting formatted timetestamp
printf -v timestamp '%(%Y-%m-%d_%H-%M-%S)T' -1

# Naming backup directory with a timestamp
backup_dir="backup_${timestamp}"

# If there is another directory with same name, don't overwri
if [[ -e "$backup_dir" ]]; then
    echo -e "${red}Backup already exists. Refusing to overwrite.${nc}"
    exit 1
fi

# If the directory is not there make it using mkdir
if ! mkdir "$backup_dir"; then
    echo -e "${red}Failed to create backup directory.${nc}"
    exit 1
fi

# Copy contents from the source
if cp -r "$src_dir" "$backup_dir/"; then
    echo -e "${green}Backup completed successfully!${nc}"
    echo "Backup location: $backup_dir"
else
    echo -e "${red}Backup failed!${nc}"
    exit 1
fi

