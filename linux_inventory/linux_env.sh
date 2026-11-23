#!/usr/bin/env bash

#Colors
readonly red='\033[0;91m'
cyan='\033[0;96m'
yellow='\033[0;93m'
bold='\033[0;1m'
white='\033[0;97m'
#Color reset
nc='\033[0m'

#Check if user has sudo privileges
if [[ "$EUID" != 0 ]]; then
    echo -e "${red}Error: Please run with sudo -> sudo $0${nc}"
    exit 126
fi

#Display
echo -e "${cyan}========================${nc}"
echo -e "${bold}LINUX SYSTEM INVENTORY${NC}"
echo -e "${cyan}========================${nc}"
echo " "

#Generating timestamp
printf -v gen_date '%(%d-%m-%Y at %H:%M:%S)T\n' -1

host=$(hostname)

#Just a simple formatted printf Function
print_f(){
    printf "%-25s ${white}%s${nc}\n" "$1" "$2"
}

#Function for system information
get_os_info(){
    local os_file="/etc/os-release"
    local kernel=$(uname -r)
    local host=$(hostname)
    local archit=$(uname -m)
    local manu=$(dmidecode -t system | grep -i Manufacture | cut -d : -f 2)
    local model=$(dmidecode -t system | grep -i Product | cut -d : -f 2)
    local uptime=$(uptime -p)
    local virtual=$(systemd-detect-virt)

    if [[ ! -r "$os_file" ]]; then
        echo -e "${red} Cannot read $os_file" >&2
        return 1
    fi
    (
    . "$os_file"
    print_f "OS:" "${NAME:-Unknown}"
    print_f "Hostname:" "${host:-Unknown}"
    print_f "Version:" "${VERSION:-Unknown}"
    print_f "Distribution Family:" "${ID_LIKE:-Unknown}"
    print_f "Kernel Version:" "${kernel:-Unknown}"
    print_f "System Architecture:" "${archit:-Unknown}"
    print_f "Manufacturer:" "${manu:-Unknown}"
    print_f "Model:" "${model:-Unknown}"
    print_f "Uptime:" "${uptime:-Unknown}"
    print_f "Virtualization:" "${virtual:-Not detectable}"

        )
}

#CPU Function with information needed
cpu_info(){
    local cpu_model=$(awk -F: '/^model name/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' /proc/cpuinfo)
    local cpu_vendor=$(awk -F: '/^vendor_id/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' /proc/cpuinfo)
    local logical_core=$(nproc)
    local physical_core=$(lscpu -b -p=Core,Socket | grep -v '^#' | sort -u | wc -l)
    local frequency=$(awk '/cpu MHz/ {sum += $4; count++} END {printf "%.2f MHz\n", sum/count}' /proc/cpuinfo)
    local usage=$(top -bn1 | awk '/^%Cpu/ {printf "%.2f%%\n", 100 - $8}')
    local load=$(awk -v c="$logical_core" '{printf "%s %s %s (%.1f%% per core)", $1, $2, $3, ($1/c)*100}' /proc/loadavg)

    print_f "CPU Model:" "${cpu_model:-Unknown}"
    print_f "CPU Vendor:" "${cpu_vendor:-Unknown}"
    print_f "Logical Cores:" "${logical_core:-Unknown}"
    print_f "Physical Cores:" "${physical_core:-Unavailable}"
    print_f "CPU Frequency:" "${frequency:-Unavailable}"
    print_f "Average CPU Usage:" "${usage:-Unavailable}"
    print_f "Average Load:" "${load:-Unavailable}"

    
}

#Memory Information(RAM)
mem_info(){
    local ram=$(awk '/MemTotal/ {printf "%.2f\n", $2 / 1024 / 1024}' /proc/meminfo)
    local used=$(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {printf "%.2f\n", (t-a) / 1024 / 1024}' /proc/meminfo)
    local usage_tage=$(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {printf "%.1f%%\n", ((t-a) / t) * 100}' /proc/meminfo)
    local available=$(awk '/MemAvailable/ {printf "%.2f\n", $2 / 1048576}' /proc/meminfo)
    local total_swap=$(awk '/SwapTotal/ {printf "%.2f\n", $2 / 1048576}' /proc/meminfo)
    local avail_swap=$(awk '/SwapTotal/ {t=$2} /SwapFree/ {f=$2} END {printf "%.2f\n", (t-f) / 1048576}' /proc/meminfo)

    print_f "Total RAM:" "${ram:-Unavailable}GiB"
    print_f "Used RAM:" "${used:-Unavailable}GiB"
    print_f "Used RAM percentage:" "${usage_tage}"
    print_f "Available RAM:" "${available}GiB"
    print_f "Total Swap:" "${total_swap}GiB"
    print_f "Available Swap:" "${avail_swap}GiB"
}
 
echo -e "${yellow}Welcome to linux system inventory.${nc}"
echo -e "${yellow}Generating system info for $host machine...\n"
sleep 2
echo -e "Linux System Information Generated on: $gen_date"
echo -e "${red}-------------------------------------${nc}"
echo -e "${cyan}1. General System Information${nc}"
echo -e "${red}-------------------------------------${nc}"
get_os_info
echo -e "${red}-------------------------------------${nc}"
echo -e "${cyan}2. CPU Information${nc}"
echo -e "${red}-------------------------------------${nc}"
cpu_info
echo -e "${red}-------------------------------------${nc}"
echo -e "${cyan}3. Memory Information${nc}"
echo -e "${red}-------------------------------------${nc}"
mem_info








