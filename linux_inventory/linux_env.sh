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

        )
}
 
echo -e "${yellow}Welcome to linux system inventory.${nc}"
echo -e "${yellow}Generating system info for $host machine...\n"
sleep 2
echo -e "Linux System Information Generated on: $gen_date"
echo -e "${red}-------------------------------------${nc}"
echo -e "${white}1. General System Information${nc}"
echo -e "${red}-------------------------------------${nc}"
get_os_info










