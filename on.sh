#!/bin/bash

# --- CONFIGURATION ---
INSTANCE_ID="i-xxxxxxxxxxxxxxxxx"      # EC2 Instance ID
AWS_PROFILE="aws-profile-name"          # AWS CLI profile
SSH_CONFIG_FILE="$HOME/.ssh/config"
SSH_ALIAS="ec2-target"
SSH_USER="remote-user"
SSH_KEY="~/.ssh/private-key.pem"
# ---------------------

# Ensure .ssh directory exists
mkdir -p "$HOME/.ssh"
touch "$SSH_CONFIG_FILE"

echo "🚀 Starting EC2 instance..."
aws ec2 start-instances \
  --instance-ids "$INSTANCE_ID" \
  --profile "$AWS_PROFILE" \
  > /dev/null

echo "⏳ Waiting for instance to be running..."
aws ec2 wait instance-running \
  --instance-ids "$INSTANCE_ID" \
  --profile "$AWS_PROFILE"

NEW_IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --profile "$AWS_PROFILE" \
  --query 'Reservations[*].Instances[*].PublicIpAddress' \
  --output text)

echo "✅ Public IP obtained: $NEW_IP"

# Remove previous SSH host entry
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "/Host $SSH_ALIAS/,/IdentityFile/d" "$SSH_CONFIG_FILE"
else
  sed -i "/Host $SSH_ALIAS/,/IdentityFile/d" "$SSH_CONFIG_FILE"
fi

# Write new SSH configuration
cat <<EOF >> "$SSH_CONFIG_FILE"
Host $SSH_ALIAS
    HostName $NEW_IP
    User $SSH_USER
    IdentityFile $SSH_KEY
    StrictHostKeyChecking no
EOF

echo "🔗 SSH configuration updated. Connect using: ssh $SSH_ALIAS"
