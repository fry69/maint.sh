# maint.sh - Server Maintenance Script

maint.sh is a Bash script designed to simplify and automate server maintenance tasks across multiple hosts. It provides a convenient way to execute common maintenance operations, such as checking resources, updating packages, and rebooting servers when necessary.

## Features

- Execute commands on multiple SSH hosts simultaneously
- Ping multiple hosts to check connectivity
- Perform common maintenance tasks:
  - Check server resources (uname, free memory, disk usage)
  - Update and upgrade packages
  - Reboot servers when required
- Execute custom commands on remote hosts
- Dry-run option to preview commands without execution
- Configurable host lists for SSH and ping operations

## Installation

1. Clone this repository or download the script files.
2. Run the installation script:

```bash
./install.sh
```

This will create a configuration directory at `$HOME/.config/maint.sh` and copy the example configuration file to `config.sh`.

## Configuration

Edit the configuration file at `$HOME/.config/maint.sh/config.sh` to set up your SSH and ping hosts:

```bash
ssh_hosts=("server1" "server2" "server3")
ping_hosts=("server1.example.com" "server2.example.com" "server3.example.com")
```

Replace the example values with your actual server hostnames or IP addresses.

## Usage

The script supports the following commands:

```
Usage: ./maint.sh [ -n ] res | upd | rbt | png | cmd <commands>
```

- `-n`: Dry-run mode (preview commands without execution)
- `res`: Check server resources (uname, free memory, disk usage)
- `upd`: Update and upgrade packages
- `rbt`: Reboot servers if required
- `png`: Ping hosts defined in the configuration
- `cmd <commands>`: Execute custom commands on remote hosts

Examples:

```bash
# Check resources on all configured SSH hosts
./maint.sh res

# Update packages on all configured SSH hosts
./maint.sh upd

# Reboot servers if required
./maint.sh rbt

# Ping all configured hosts
./maint.sh png

# Execute a custom command on all configured SSH hosts
./maint.sh cmd "ls -la /var/log"
./maint.sh cmd "systemctl status | head -n 5"

# Dry-run mode: preview the update command without execution
./maint.sh -n upd
```

## License

This project is licensed under the [MIT License](LICENSE).

## Contributing

Contributions to improve maint.sh are welcome. Please feel free to submit pull requests or open issues to discuss potential improvements or report bugs.