# maint.sh - Simple Server Maintenance Script

maint.sh is a basic Bash script designed for simple maintenance tasks across a very small number of servers (less than 10). It provides a quick way to execute common maintenance operations, such as checking resources, updating packages, and rebooting servers when necessary.

## Important Note

This script is intentionally simple and borderline naive in its approach. It is suitable for personal use or managing a handful of servers. For serious maintenance tasks or larger server fleets, it is strongly recommended to use a more robust tool like Ansible.

## Features

- Execute basic commands on multiple SSH hosts (up to 10)
- Ping multiple hosts to check connectivity
- Perform simple maintenance tasks:
  - Check server resources (uname, free memory, disk usage)
  - Update and upgrade packages
  - Reboot servers when required
- Execute custom commands on remote hosts
- Dry-run option to preview commands without execution
- Configurable host lists for SSH and ping operations

## When to Use This Script

- Personal projects with a few servers
- Quick checks on a small number of machines
- Learning and understanding basic server maintenance concepts

## When NOT to Use This Script

- Production environments
- Managing more than 10 servers
- Complex deployment scenarios
- Environments requiring fine-grained access control
- Situations where audit trails and logging are critical

For these scenarios, please consider using Ansible or other professional configuration management and orchestration tools.

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

Replace the example values with your actual server hostnames or IP addresses. Remember, this script is designed for a small number of servers (less than 10).

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

# Dry-run mode: preview the update command without execution
./maint.sh -n upd
```

## License

This project is licensed under the [MIT License](LICENSE).

## Contributing

While this script is intentionally kept simple, minor improvements or bug fixes are welcome. Please feel free to submit pull requests or open issues to discuss potential improvements or report bugs. However, keep in mind that major feature additions are out of scope for this project.

## Disclaimer

This script is provided as-is, without any warranties or guarantees. Use at your own risk. Always test thoroughly before using in any environment.
