#!/bin/bash

# --- CONFIGURATION ---
INSTANCE_ID="i-xxxxxxxxxxxxxxxxx"   # EC2 Instance ID
AWS_PROFILE="aws-profile-name"       # AWS CLI profile
# ---------------------

echo "🛑 Stopping EC2 instance..."
aws ec2 stop-instances \
  --instance-ids "$INSTANCE_ID" \
  --profile "$AWS_PROFILE" \
  > /dev/null

echo "💸 Instance stopped. Cost savings engaged."
