#!/usr/bin/env bash

# Safety: exit on errors, unset vars, and track errors from pipes
set -Eeuo pipefail

# Function to check if awk is available
check_awk() {
    if command -v awk >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Set flag for awk availability
awk_available=0
if check_awk; then
    awk_available=1
fi

config_file=$HOME/.config/maint.sh/config.sh

if [ -f "$config_file" ]; then
    source $config_file
else
    echo "Configuration file not found."
    exit 1
fi

if [ -z "${ssh_hosts+x}" ]; then 
    echo "ssh_hosts variable not set in configuration file."
    exit 1
fi

tmp_dir="/tmp/server_maintenance_$$"  # Unique temp directory based on PID

# Function to get Hostname from SSH config
get_hostname() {
    local host="$1"
    if [ $awk_available -eq 1 ]; then
        awk -v host="$host" '
            $1 == "Host" && $2 == host {found=1; next}
            found && $1 == "Hostname" {print $2; exit}
            $1 == "Host" {found=0}
        ' ~/.ssh/config
    else
        echo "$host"
    fi
}

# Derive ping_hosts from ssh_hosts
ping_hosts=()
if [ $awk_available -eq 1 ]; then
    for host in "${ssh_hosts[@]}"; do
        hostname=$(get_hostname "$host")
        if [ -n "$hostname" ]; then
            ping_hosts+=("$hostname")
        else
            echo "Warning: No Hostname found for $host in SSH config" >&2
        fi
    done

    if [ ${#ping_hosts[@]} -eq 0 ]; then
        echo "No valid Hostnames found in SSH config for the given ssh_hosts."
        exit 1
    fi
else
    ping_hosts=("${ssh_hosts[@]}")
fi

# Create a temporary directory for output files
mkdir -p "$tmp_dir"

# Ensure temporary directory is removed upon script exit
trap 'rm -rf "$tmp_dir"' EXIT

# Function to execute remote commands
remote() {
    TIMEFORMAT='Elapsed time: %R seconds'
    time {
        echo "------------------------------ start --------------------------------"
        
        # Iterate over each SSH host
        for host in "${ssh_hosts[@]}"; do
            ssh_command=("ssh" "$host" "$@")
            if [[ -n "${dry_run:-}" ]]; then
                echo "${ssh_command[*]}"
            else
                echo "Executing on $host: ${ssh_command[*]}"
                # Redirect both stdout and stderr to unique files
                "${ssh_command[@]}" >"$tmp_dir/out_${host}.log" 2>"$tmp_dir/err_${host}.log" &
            fi
        done
        
        # Wait for all background SSH commands to finish
        wait
        
        # Process outputs for each host
        for host in "${ssh_hosts[@]}"; do
            echo "------------------------------ $host -----------------------"
            if [[ -f "$tmp_dir/out_${host}.log" ]]; then
                echo "Standard Output:"
                cat "$tmp_dir/out_${host}.log"
            fi
            if [[ -s "$tmp_dir/err_${host}.log" ]]; then
                echo "Standard Error:"
                cat "$tmp_dir/err_${host}.log"
            fi
        done
        
        echo "------------------------------- end ---------------------------------"
    }
}

# Function to ping hosts
ping_hosts_func() {
    if [ $awk_available -eq 0 ]; then
        echo "Ping functionality is disabled because 'awk' is not available."
        return
    fi
    for host in "${ping_hosts[@]}"; do
        ping_command=("ping6" "-q" "-o" "-c" "1" "$host")
        if [[ -n "${dry_run:-}" ]]; then
            echo "${ping_command[*]}"
        else
            if "${ping_command[@]}"; then
                echo "Ping to $host successful."
            else
                echo "Ping to $host failed." >&2
            fi
        fi
    done
}

# Function to display usage
usage() {
    echo "Usage: $0 [ -n ] res | upd | rbt | png | cmd <commands>"
    exit 1
}

# Ensure at least one argument is provided
if [[ "$#" -lt 1 ]]; then
    usage
fi

# Parse options and arguments
dry_run=""
commands=()

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -n)
            dry_run=true
            shift
            ;;
        res|upd|rbt|png|cmd)
            commands+=("$1")
            shift
            # For 'cmd', capture all remaining arguments as the command
            if [[ "${commands[-1]}" == "cmd" ]]; then
                if [[ "$#" -lt 1 ]]; then
                    echo "Error: 'cmd' requires an argument." >&2
                    exit 1
                fi
                commands+=("$@")
                break
            fi
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            ;;
    esac
done

# Execute the appropriate command(s)
for ((i=0; i<${#commands[@]}; i++)); do
    case "${commands[i]}" in
        res)
            remote "uname -a; free -h; echo; df -h /"
            ;;
        upd)
            remote "uname -a; date; sudo apt-get update && sudo apt-get -y dist-upgrade"
            ;;
        rbt)
            remote "if [ -f /run/reboot-required ]; then echo Rebooting; sudo shutdown -r now; else echo No reboot necessary; fi"
            ;;
        png)
            ping_hosts_func
            ;;
        cmd)
            # Collect all remaining commands after 'cmd'
            cmd_args=("${commands[@]:i+1}")
            remote "${cmd_args[@]}"
            break
            ;;
        *)
            echo "Unknown command: ${commands[i]}" >&2
            usage
            ;;
    esac
done
