#!/usr/bin/env bash

# Exit immediately on errors, treat unset variables as errors, and ensure pipeline failures are caught
set -Eeuo pipefail

# ============================ #
#          CONFIGURATION       #
# ============================ #

# Path to the SSH configuration
SSH_CONFIG="$HOME/.ssh/config"

# Create a unique temporary directory using mktemp for better security
TMP_DIR=$(mktemp -d "/tmp/server_maintenance_XXXXXX")

# Ensure the temporary directory is removed when the script exits
trap 'rm -rf "$TMP_DIR"' EXIT

# ============================ #
#         HELPER FUNCTIONS     #
# ============================ #

# Function to display usage instructions
usage() {
    cat <<EOF
Usage: $0 [ -n ] <command> [arguments]

Commands:
  res           Display system resources.
  upd           Update system packages.
  rbt           Reboot if required.
  sys           Show SystemD status.
  png           Ping hosts.
  cmd <command> Execute a custom command on all hosts.

Options:
  -n            Dry run. Show the commands without executing them.
EOF
    exit 1
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if awk is available
check_awk() {
    if command_exists awk; then
        return 0
    else
        return 1
    fi
}

# Function to extract the Hostname from SSH config for a given host
get_hostname() {
    local host="$1"
    awk -v host="$host" '
        $1 == "Host" && $2 == host {found=1; next}
        found && $1 == "Hostname" {print $2; exit}
        $1 == "Host" {found=0}
    ' "$SSH_CONFIG"
}

# Function to execute remote commands on all SSH hosts
remote() {
    local cmd="$*"
    if [[ -z "${dry_run:-}" ]]; then
        echo "------------------------------ Start --------------------------------"

        # Iterate over each SSH host
        for host in "${ssh_hosts[@]}"; do
            echo "Executing on $host: $cmd"
            # Execute the command in the background and redirect output and error
            ssh "$host" "$cmd" >"$TMP_DIR/out_${host}.log" 2>"$TMP_DIR/err_${host}.log" &
        done

        # Wait for all background SSH commands to finish
        wait

        # Process and display outputs for each host
        for host in "${ssh_hosts[@]}"; do
            echo "------------------------------ $host ------------------------------"
            if [[ -f "$TMP_DIR/out_${host}.log" ]]; then
                echo "Standard Output:"
                cat "$TMP_DIR/out_${host}.log"
            fi
            if [[ -s "$TMP_DIR/err_${host}.log" ]]; then
                echo "Standard Error:"
                cat "$TMP_DIR/err_${host}.log"
            fi
        done

        echo "------------------------------- End ---------------------------------"
    else
        # Dry run mode: Show the SSH commands without executing
        echo "------------------------------ Start (Dry Run) ------------------------------"
        for host in "${ssh_hosts[@]}"; do
            echo "ssh $host \"$cmd\""
        done
        echo "------------------------------- End (Dry Run) ---------------------------------"
    fi
}

# Function to ping all derived hosts
ping_hosts_func() {
    if [[ $AWK_AVAILABLE -eq 0 ]]; then
        echo "Ping functionality is disabled because 'awk' is not available." >&2
        return
    fi

    for host in "${ping_hosts[@]}"; do
        if [[ -n "${dry_run:-}" ]]; then
            echo "ping6 -q -o -c 1 $host"
        else
            if ping6 -q -o -c 1 "$host" >/dev/null 2>&1; then
                echo "Ping to $host successful."
            else
                echo "Ping to $host failed." >&2
            fi
        fi
    done
}

# ============================ #
#          INITIAL SETUP       #
# ============================ #

# Check for awk availability and set flag
AWK_AVAILABLE=0
if check_awk; then
    AWK_AVAILABLE=1
else
    echo "Error: 'awk' is not available. Please install awk to use this script." >&2
    exit 1
fi

# Ensure the SSH configuration file exists
if [[ ! -f "$SSH_CONFIG" ]]; then
    echo "Error: SSH configuration file not found at '$SSH_CONFIG'." >&2
    exit 1
fi

# Derive ssh_hosts from SSH config: only Host entries preceded by '# maint.sh'
declare -a ssh_hosts=()

if [[ $AWK_AVAILABLE -eq 1 ]]; then
    # Parse the SSH config to extract hosts with '# maint.sh' comment
    ssh_hosts=($(awk '
        /^# maint.sh$/ {flag=1; next}
        /^Host / && flag { 
            for(i=2;i<=NF;i++) if ($i !~ /^#/) print $i
            flag=0 
        }
        /^Host / {flag=0}
    ' "$SSH_CONFIG"))
else
    echo "Error: 'awk' is not available. Cannot parse SSH config." >&2
    exit 1
fi

# Check if any ssh_hosts were found
if [[ ${#ssh_hosts[@]} -eq 0 ]]; then
    echo "Error: No SSH hosts with '# maint.sh' comment found in '$SSH_CONFIG'." >&2
    exit 1
fi

# Derive ping_hosts from ssh_hosts
declare -a ping_hosts=()
if [[ $AWK_AVAILABLE -eq 1 ]]; then
    while IFS= read -r host; do
        hostname=$(get_hostname "$host")
        if [[ -n "$hostname" ]]; then
            ping_hosts+=("$hostname")
        else
            echo "Warning: No Hostname found for '$host' in SSH config." >&2
        fi
    done < <(printf "%s\n" "${ssh_hosts[@]}")

    if [[ ${#ping_hosts[@]} -eq 0 ]]; then
        echo "Error: No valid Hostnames found in SSH config for the given ssh_hosts." >&2
        exit 1
    fi
else
    ping_hosts=("${ssh_hosts[@]}")
fi

# ============================ #
#           MAIN LOGIC         #
# ============================ #

# Ensure at least one argument is provided
if [[ "$#" -lt 1 ]]; then
    usage
fi

# Parse options and arguments
dry_run=""
declare -a commands=()

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -n)
            dry_run=true
            shift
            ;;
        res|upd|rbt|sys|png|cmd)
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
            echo "Error: Unknown option or command: '$1'" >&2
            usage
            ;;
    esac
done

# Execute the appropriate commands
for ((i=0; i<${#commands[@]}; i++)); do
    case "${commands[i]}" in
        res)
            remote "uname -a; free -h; echo; df -h /"
            ;;
        upd)
            remote "uname -a; date; sudo apt-get update && sudo apt-get -y dist-upgrade"
            ;;
        rbt)
            remote "if [[ -f /run/reboot-required ]]; then echo 'Rebooting'; sudo shutdown -r now; else echo 'No reboot necessary'; fi"
            ;;
        sys)
            remote "systemctl status | head -n 5"
            ;;
        png)
            ping_hosts_func
            ;;
        cmd)
            # Collect all remaining arguments after 'cmd' as the command
            cmd_args=("${commands[@]:i+1}")
            remote "${cmd_args[@]}"
            break
            ;;
        *)
            echo "Error: Unknown command: '${commands[i]}'" >&2
            usage
            ;;
    esac
done