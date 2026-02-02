# aws-c2-launcher

Bash script to start a specific EC2 instance, wait until it has a public IP, update your `~/.ssh/config` with a dedicated host alias (for example `YourHostName`), and leave everything ready so you can simply run:

Compatible with macOS and Termux / NetHunter (Android), with support for:

- Pre-execution authentication (fingerprint / fingerprint or sudo)
- Notifications:
  - macOS: Native notifications via osascript
  - Termux: termux-notification (requires termux-api)

---

## Features

- Starts a specific EC2 instance by `INSTANCE_ID`
- Waits until the instance reaches the running state
- Polls until a public IP address is assigned
- Writes or updates a managed block in `~/.ssh/config`:
  - Host `YourHostName` (configurable)
  - HostName: latest public IP
  - User: configured SSH user (kali, ubuntu, ec2-user, etc.)
  - IdentityFile: path to your private key (`.pem` or equivalent)
- Sends a notification when the C2 instance is ready
- Uses strict Bash mode (`set -Eeuo pipefail`)
- Verifies required binaries before execution

---

## Requirements

### Common

- An existing EC2 instance accessible via SSH
- AWS CLI configured with a profile that has permissions for the instance:
  - `ec2:StartInstances`
  - `ec2:DescribeInstances`
  - (Optional) `ec2:StopInstances` if you use a shutdown script
- A valid private key for the instance
- A Security Group allowing TCP 22 from your IP

---

### macOS

- `bash`
- `awscli`
- `awk` (BSD awk included by default)
- `ssh` (OpenSSH, preinstalled)
- Optional:
  - fingerprint support for sudo
  - `osascript` (included in macOS) for notifications

Install AWS CLI via Homebrew:

```bash
brew install awscli
```

---

### Termux / NetHunter (Android)

Recommended packages:

```bash
pkg update
pkg install bash gawk openssh coreutils awscli
pkg install termux-api
```

You must also install the **Termux:API** app from the Play Store or F-Droid for:

- `termux-fingerprint`
- `termux-notification`

---

## Configuration

Main variables are defined in the script with defaults, but they can also be overridden via environment variables.

### Common variables

| Variable | Description | Example |
|----------|-------------|---------|
| `INSTANCE_ID` | EC2 instance ID | `i-xxxxxxxxxxxxxxx` |
| `PROFILE` | AWS CLI profile | `YourProfile` |
| `AWS_REGION` | AWS region | `AWS-Region-1` |
| `HOST_ALIAS` | SSH host alias | `YourHostName` |
| `SSH_USER` | SSH username | `kali`, `ubuntu`, `ec2-user` |
| `IDENTITY_FILE` | Path to private key | `$HOME/privkey.pem` |
| `SSH_CONFIG_FILE` | SSH config path | `$HOME/.ssh/config` |

You can either edit the script directly or export variables before execution:

```bash
export INSTANCE_ID="i-xxxxxxxxxxxxxxx"
export PROFILE="my-profile"
export AWS_REGION="AWS-Region-1"
export SSH_USER="ubuntu"
export IDENTITY_FILE="$HOME/path/yourprivkey.pem"

./on.sh
```

---

## Usage

1. Clone the repository:

   ```bash
   git clone https://github.com/YOUR_USERNAME/aws-c2-launcher.git
   cd aws-c2-launcher
   ```

2. Make the script executable:

   ```bash
   chmod +x on.sh
   ```

3. (Optional) Configure variables in the script or via environment variables

4. Run the script:

   ```bash
   ./on.sh
   ```

5. When finished, you'll see:

   ```text
   Public IP obtained: x.x.x.x
   Ready. Connect using: ssh YourHostName
   ```

6. Connect to your C2:

   ```bash
   ssh YourHostName
   ```

Optional: add a shell alias:

```bash
echo "alias YourHostName='ssh YourHostName'" >> ~/.zshrc   # zsh
echo "alias YourHostName='ssh YourHostName'" >> ~/.bashrc  # bash
```

---

## Notifications & Authentication

### macOS

- The script may request authentication (sudo → fingerprint if enabled) before starting the instance
- Uses `osascript` to show a native notification when the C2 is ready

### Termux / NetHunter

- If `termux-fingerprint` is available, the script can abort if biometric authentication fails or is canceled
- If `termux-notification` is available, it sends a notification like: `C2 ready at <IP>`

---

## Disclaimer

> **Warning:** This project is intended for authorized security research, lab environments, and personal infrastructure only.
> Use responsibly and ensure compliance with AWS policies and applicable laws.
