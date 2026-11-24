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

#Smart disk Function
smart(){
    # Check if smartctl is available
    if ! command -v smartctl >/dev/null 2>&1; then
        echo "Error: smartmontools is not installed."
        return 1
    fi

    # Auto-detect all physical disks (excludes partitions, loop, and rom devices)
    local DISKS
    DISKS=$(lsblk -dn -o NAME,TYPE | awk '$2=="disk" {print "/dev/"$1}')

    for disk in $DISKS; do
        # Extract PASSED/FAILED status (handles both SATA and NVMe output formats)
        local HEALTH
        HEALTH=$(sudo smartctl -H "$disk" 2>/dev/null | awk -F': ' '/overall-health|SMART Health Status/ {print $2}')
        
        # Fallback if drive is virtual (VM) or doesn't support SMART
        echo "Disk: $disk | Health: ${HEALTH:-Not Supported / Virtual}"
    done
}

# Storage information Function
storage_info(){
    local physical_model=$(lsblk -dn -e 7 -o MODEL)
    local physical_size=$(lsblk -dn -e 7 -o SIZE)
    local storage_used=$(df -h / | awk 'NR==2 {print $3}')
    local storage_available=$(df -h / | awk 'NR==2 {print $4}')
    local filesystem_type=$(df -T / | awk 'NR==2 {print $2}')
    local health=$(smart)
    
    print_f "Disk Model:" "${physical_model:-Unknown}"
    print_f "Disk Size:" "${physical_size:-Unknown}"
    print_f "Storage Used:" "${storage_used:-Not Detected}"
    print_f "Storage Available:" "${storage_available}"
    print_f "Filesystem Type:" "${filesystem_type:-Unknown}"
    print_f "Health:" "${health:-Undetected}"
}

#Network interface Function
net_func() {
    local iface name state color

    printf "%-25s %s\n" "INTERFACE" "STATUS"
    printf "%-25s %s\n" "---------" "------"

    for iface in /sys/class/net/*; do
        name=$(basename "$iface")
        state=$(<"$iface/operstate") # Slightly faster Bash built-in than `cat`

        case "$state" in
            up)   color="$nc" ;; 
            down) color="$red" ;;
            *)    color="$yellow" ;;
        esac

        printf "%-25s ${color}%s${NC}\n" "$name" "${state^^}"
    done
}

#IP extraction

check_network_info() {
    echo "=== Network Information ==="

    # 1. Primary active interface & IPv4 Default Gateway
    local active_iface gw_ipv4 gw_ipv6
    active_iface=$(ip -4 route show default 2>/dev/null | awk '{print $5; exit}')
    gw_ipv4=$(ip -4 route show default 2>/dev/null | awk '{print $3; exit}')
    gw_ipv6=$(ip -6 route show default 2>/dev/null | awk '{print $3; exit}')

    if [[ -z "$active_iface" ]]; then
        echo "Connection Status: Disconnected (No default route)"
        return 1
    fi

    # 2. Connection Type (Wi-Fi vs Ethernet)
    local conn_type="Ethernet"
    if [[ -d "/sys/class/net/$active_iface/wireless" ]] || [[ "$active_iface" == wl* ]]; then
        conn_type="Wi-Fi"
    fi

    # 3. MAC Address
    local mac_addr
    [[ -r "/sys/class/net/$active_iface/address" ]] && mac_addr=$(<"/sys/class/net/$active_iface/address")
        # 6. DNS Configuration (systemd-resolved with /etc/resolv.conf fallback)
    local dns_servers search_domains
    if command -v resolvectl &>/dev/null && systemctl is-active --quiet systemd-resolved; then
        # Get upstream DNS servers for the active interface (or global fallback)
        dns_servers=$(resolvectl dns "$active_iface" 2>/dev/null | sed 's/^.*: //')
        [[ -z "$dns_servers" ]] && dns_servers=$(resolvectl dns 2>/dev/null | awk '{for(i=4;i<=NF;i++) printf "%s ", $i}' | xargs)
        
        search_domains=$(resolvectl domain "$active_iface" 2>/dev/null | sed 's/^.*: //')
    else
        # Fallback to traditional /etc/resolv.conf
        dns_servers=$(awk '/^nameserver/ {print $2}' /etc/resolv.conf 2>/dev/null | xargs)
        search_domains=$(awk '/^(search|domain)/ {for(i=2;i<=NF;i++) printf "%s ", $i}' /etc/resolv.conf 2>/dev/null | xargs)
    fi


    # 4. IPv4 and IPv6 Addresses
    local ipv4 ipv6
    ipv4=$(ip -4 -o addr show dev "$active_iface" scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
    ipv6=$(ip -6 -o addr show dev "$active_iface" scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)

    print_f "Active Interface:" "$active_iface"
    print_f "Connection Type:" "$conn_type"
    print_f "MAC Address:"  "${mac_addr:-Unavailable}"
    print_f "IPv4 Address:" "${ipv4:-None}"
    print_f "IPv4 Gateway:" "${gw_ipv4:-None}"
    print_f "IPv6 Address:" "${ipv6:-None}"
    print_f "IPv6 Gateway:" "${gw_ipv6:-None}"
    print_f "DNS Servers:" "${dns_servers:-None}"
    print_f "Search Domains:" "${search_domains:-None}"


    # 5. Full IPv4 Routing Table
    echo "--- IPv4 Routing Table ---"
  
printf "%b%s%b\n" "$cyan" "$(ip -4 route show | sed 's/^/  /')" "$nc"
}
check_security_network() {
    echo "=== Firewall & VPN Status ==="

    # 1. Detect Firewall Status
    local fw_status="Inactive or None detected"
    if command -v ufw &>/dev/null && ufw status 2>/dev/null | grep -q "Status: active"; then
        fw_status="Active (UFW)"
    elif command -v firewall-cmd &>/dev/null && firewall-cmd --state &>/dev/null; then
        local active_zone
        active_zone=$(firewall-cmd --get-active-zones 2>/dev/null | head -n1)
        fw_status="Active (firewalld - Zone: ${active_zone:-default})"
    elif command -v nft &>/dev/null && [[ -n "$(nft list ruleset 2>/dev/null)" ]]; then
        fw_status="Active (nftables rules loaded)"
    elif command -v iptables &>/dev/null && [[ $(iptables -S 2>/dev/null | wc -l) -gt 3 ]]; then
        fw_status="Active (iptables rules loaded)"
    elif [[ $EUID -ne 0 ]]; then
        fw_status="Unknown (Run with sudo to inspect firewall rules)"
    fi

    # 2. Detect Active VPN Connections
    local vpn_list=()

    # Method A: Check NetworkManager active VPNs (if nmcli is installed)
    if command -v nmcli &>/dev/null; then
        while IFS=: read -r name type; do
            [[ "$type" == "vpn" || "$type" == "wireguard" ]] && vpn_list+=("$name ($type)")
        done < <(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null)
    fi

    # Method B: Check active virtual tunnel interfaces (OpenVPN, WireGuard, Tailscale, ZeroTier, Cisco)
    local iface
    for iface in /sys/class/net/*; do
        iface=$(basename "$iface")
        if [[ "$iface" =~ ^(tun|tap|wg|tailscale|zt|ppp|cscotun)[0-9a-zA-Z_-]*$ ]]; then
            # Avoid duplicates if already caught by nmcli
            if [[ ! " ${vpn_list[*]} " =~ " $iface " ]]; then
                vpn_list+=("Interface: $iface")
            fi
        fi
    done

    local vpn_status="Disconnected"
    if [[ ${#vpn_list[@]} -gt 0 ]]; then
        # Join array elements with commas
        vpn_status="Connected ($(IFS=', '; echo "${vpn_list[*]}"))"
    fi

    print_f "Firewall Status:" "$fw_status"
    print_f "VPN Status:" "$vpn_status"
}


#Network information
net_info(){
    net_func
    check_network_info
    check_security_network
}
#user groups
get_groups(){
    read -ra all_groups <<< "$(id -Gn)"
    local primary="${all_groups[0]}"
    local secondary=("${all_groups[@]:1}")
    print_f "Primary Group:" "$primary"
    local sec_list
    sec_list=$(IFS=", "; echo "${secondary[*]}")
    print_f "Secondary Group(s):" "${secondary:-Root}"
}

#Login sessions
get_sessions() {
    # Format: username (terminal) [IP/Display if present]
    local sessions
    sessions=$(who | awk '{
        ip = ($5 != "") ? " " $5 : "";
        printf "%s (%s%s), ", $1, $2, ip
    }' | sed 's/, $//')

    if [[ -z "$sessions" ]]; then
        echo "None"
    else
        echo "$sessions"
    fi
}
#Last login information
get_last_login() {
    # Grab the 2nd entry (previous login); -w prevents username truncation
    local entry
    entry=$(last -w -n 2 "$USER" 2>/dev/null | sed -n '2p')

    if [[ -z "$entry" || "$entry" == wtmp* ]]; then
        echo "First login / No record"
    else
        # Extract TTY ($2), Host/IP ($3), and Timestamp ($4-$7)
        echo "$entry" | awk '{
            source = ($3 ~ /^[0-9.:a-fA-F]+$/) ? $3 : $2;
            printf "%s %s %s %s (%s)\n", $4, $5, $6, $7, source
        }'
    fi
}
#SSH Configuration
check_ssh_config() {
    local target_user="${1:-$USER}"
    local user_home
    user_home=$(getent passwd "$target_user" | cut -d: -f6)

    if [[ -z "$user_home" || ! -d "$user_home" ]]; then
        echo "Error: Home directory for '$target_user' not found."
        return 1
    fi

    echo "=== SSH Access Configuration for: $target_user ==="

    # 1. Check ~/.ssh directory & permissions (should be 700)
    local ssh_dir="$user_home/.ssh"
    if [[ -d "$ssh_dir" ]]; then
        local dir_perms
        dir_perms=$(stat -c "%a" "$ssh_dir")
        print_f "SSH Directory:" "Exists (Permissions: $dir_perms)"
    else
        print_f "SSH Directory:" "Not found ($ssh_dir)"
    fi

    # 2. Check authorized_keys (count & permissions, should be 600)
    local auth_keys="$ssh_dir/authorized_keys"
    if [[ -f "$auth_keys" ]]; then
        local key_perms key_count
        key_perms=$(stat -c "%a" "$auth_keys")
        # Count non-empty, non-comment lines
        key_count=$(grep -cve '^\s*$' -e '^\s*#' "$auth_keys" 2>/dev/null || echo 0)
        print_f "Authorized Keys:" "$key_count key(s) configured (Permissions: $key_perms)"
    else
        print_f "Authorized Keys:"   "None"
    fi

    # 3. Check user's public/private key pairs
    local pub_keys
    pub_keys=$(find "$ssh_dir" -maxdepth 1 -name "*.pub" -printf "%f " 2>/dev/null)
    print_f "User Public Keys:"  "${pub_keys:-None}"

    # 4. Check effective SSH daemon rules for this user (requires root/sudo)
    if command -v sshd &>/dev/null && [[ $EUID -eq 0 ]]; then
        echo "--- Effective SSHD Policy for $target_user ---"
        sshd -T -C user="$target_user" 2>/dev/null | grep -E "^(pubkeyauthentication|passwordauthentication|permitrootlogin|allowusers|denyusers|allowgroups|denygroups) "
    else
        echo "SSHD Policy Check: Run script as root/sudo to evaluate effective sshd -T rules."
    fi
}

#User information
user_info(){
    local username=${USER}
    local uid=${UID}
    local shell=${SHELL}

    print_f "Username:" "$username"
    print_f "User ID:" "$uid - Because you used sudo ;)"
    print_f "Default Shell:" "$shell"
    get_groups
    print_f "Sessions:" "$(get_sessions)"
    print_f "Last login:" "$(get_last_login)"
    print_f "SSH Info:" "$(check_ssh_config)"

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
echo -e "${red}-------------------------------------${nc}"
echo -e "${cyan}4. Storage Information${nc}"
echo -e "${red}-------------------------------------${nc}"
storage_info
echo -e "${red}-------------------------------------${nc}"
echo -e "${cyan}5. User Information${nc}"
echo -e "${red}-------------------------------------${nc}"
user_info
echo -e "${red}-------------------------------------${nc}"
echo -e "${cyan}6. Network Information${nc}"
echo -e "${red}-------------------------------------${nc}"
net_info







