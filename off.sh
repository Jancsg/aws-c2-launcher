#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# ---- CONFIG (override vía variables de entorno) ----
INSTANCE_ID="${INSTANCE_ID:-i-xxxxxxxxxxxxxxxxx}"
AWS_PROFILE="${AWS_PROFILE:-aws-profile-name}"
AWS_REGION="${AWS_REGION:-}"   # opcional (ej. us-east-1)
# --------------------------------------------------

log() { printf '%s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

command -v aws >/dev/null 2>&1 || die "Command not found: aws"

aws_args=(--profile "$AWS_PROFILE")
[[ -n "$AWS_REGION" ]] && aws_args+=(--region "$AWS_REGION")

log "Stopping EC2 instance ($INSTANCE_ID)..."
aws ec2 stop-instances \
  --instance-ids "$INSTANCE_ID" \
  "${aws_args[@]}" \
  >/dev/null

log "Waiting for instance state: stopped..."
aws ec2 wait instance-stopped \
  --instance-ids "$INSTANCE_ID" \
  "${aws_args[@]}"

log "Done. Instance stopped."
