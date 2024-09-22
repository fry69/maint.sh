# maint.sh - Simple Server Maintenance Script

`maint.sh` is a basic Bash script designed for simple maintenance tasks across a very small number of servers (less than 10). It provides a quick way to execute common maintenance operations, such as checking resources, updating packages, and rebooting servers when necessary.

> [!Warning]
> This script is intentionally simple and borderline naive in its approach. It is suitable for personal use or managing a handful of servers. For serious maintenance tasks or larger server fleets, it is strongly recommended to use a more robust tool like Ansible.

## Features

- Execute basic commands on multiple SSH hosts (up to 10)
- Ping multiple hosts to check connectivity
- Perform simple maintenance tasks:
  - Check server resources (uname, free memory, disk usage)
  - Update and upgrade packages
  - Reboot servers when required
- Execute custom commands on remote hosts
- Dry-run option to preview commands without execution

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

1. **Download the Script**

   Download the `maint.sh` script and place it somewhere within your `$PATH`. For example, you can place it in your home directory `~/bin`:

   ```bash
   mv maint.sh ~/bin/maint.sh
   ```

2. **Make the Script Executable**

   Ensure that the script has execute permissions:

   ```bash
   chmod +x ~/bin/maint.sh
   ```

## Dependencies

- **`awk`:** The script relies on `awk` for parsing the SSH configuration. Ensure it is installed on your system.

- **SSH Access:** Passwordless SSH access (e.g., via SSH keys) to the managed hosts is recommended for seamless operation.

## Configuration

Configure your SSH hosts within your `~/.ssh/config` file. The script will automatically derive available ssh hosts from this configuration.

### Sample `~/.ssh/config` Entry

```ssh
# maint.sh
Host server1
    Hostname server1.example.com
    User root

# maint.sh
Host server2
    Hostname server2.example.com
    User admin

# maint.sh
Host server3
    Hostname server3.example.com
    User deploy
```

> [!NOTE]
> Only the `Host` entries with the `# maint.sh` comment are recognized and managed by the script.

## Usage

The script supports the following commands:

```bash
Usage: maint.sh [ -n ] res | upd | rbt | sys | png | cmd <commands>
```

### Options:

- `-n`: Dry-run mode (preview commands without execution)

### Commands:

- `res`: Check server resources (uname, free memory, disk usage)
- `upd`: Update and upgrade packages
- `rbt`: Reboot servers if required
- `sys`: Show systemd status
- `png`: Ping hosts defined in the SSH configuration
- `cmd <commands>`: Execute custom commands on remote hosts

### Examples:

1. **Check Resources on All Configured SSH Hosts**

   ```bash
   maint.sh res
   ```

2. **Update Packages on All Configured SSH Hosts**

   ```bash
   maint.sh upd
   ```

3. **Reboot Servers if Required**

   ```bash
   maint.sh rbt
   ```

4. **Show systemd Status**

   ```bash
   maint.sh sys
   ```

5. **Ping All Configured Hosts**

   ```bash
   maint.sh png
   ```

6. **Execute a Custom Command on All Configured SSH Hosts**

   ```bash
   maint.sh cmd "ls -la /var/log"
   ```

7. **Dry-Run Mode: Preview the Update Command Without Execution**

   ```bash
   maint.sh -n upd
   ```

   *Output will display the SSH commands that would be executed without actually running them.*

## License

This project is licensed under the [MIT License](LICENSE).

## Contributing

While this script is intentionally kept simple, minor improvements or bug fixes are welcome. Please feel free to submit pull requests or open issues to discuss potential improvements or report bugs. However, keep in mind that major feature additions are out of scope for this project.

## Disclaimer

This script is provided as-is, without any warranties or guarantees. Use at your own risk. Always test thoroughly before using in any environment.