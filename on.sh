#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# ---- CONFIG (override vía variables de entorno) ----
INSTANCE_ID="${INSTANCE_ID:-i-xxxxxxxxxxxxxxxxx}"
AWS_PROFILE="${AWS_PROFILE:-aws-profile-name}"
AWS_REGION="${AWS_REGION:-us-east-1}"   # ajusta o déjalo vacío

HOST_ALIAS="${HOST_ALIAS:-ec2-target}"
SSH_USER="${SSH_USER:-remote-user}"     # ej. ubuntu / ec2-user
IDENTITY_FILE="${IDENTITY_FILE:-$HOME/.ssh/private-key.pem}"
SSH_CONFIG_FILE="${SSH_CONFIG_FILE:-$HOME/.ssh/config}"

IP_RETRIES="${IP_RETRIES:-30}"
IP_SLEEP_SECONDS="${IP_SLEEP_SECONDS:-2}"
# --------------------------------------------------

log() { printf '%s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }
require_cmd() { command -v "$1" >/dev/null 2>&1 || die "Command not found: $1"; }

aws_args=(--profile "$AWS_PROFILE")
[[ -n "${AWS_REGION:-}" ]] && aws_args+=(--region "$AWS_REGION")

cleanup() {
  [[ -n "${TMP_FILE:-}" && -f "${TMP_FILE:-}" ]] && rm -f "$TMP_FILE"
}
trap cleanup EXIT

require_cmd aws
require_cmd awk
require_cmd mktemp

# Preparar ~/.ssh sin recrear innecesariamente
[[ -d "$HOME/.ssh" ]] || mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh" 2>/dev/null || true
[[ -f "$SSH_CONFIG_FILE" ]] || : > "$SSH_CONFIG_FILE"
chmod 600 "$SSH_CONFIG_FILE" 2>/dev/null || true

# Validar llave privada
[[ -f "$IDENTITY_FILE" ]] || die "IdentityFile not found: $IDENTITY_FILE"
chmod 600 "$IDENTITY_FILE" 2>/dev/null || true

log "Starting EC2 instance ($INSTANCE_ID)..."
aws ec2 start-instances \
  --instance-ids "$INSTANCE_ID" \
  "${aws_args[@]}" \
  >/dev/null

log "Waiting for instance state: running..."
aws ec2 wait instance-running \
  --instance-ids "$INSTANCE_ID" \
  "${aws_args[@]}"

log "Waiting for public IP..."
NEW_IP=""
for ((i=1; i<=IP_RETRIES; i++)); do
  NEW_IP="$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    "${aws_args[@]}" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text 2>/dev/null || true)"

  [[ -n "$NEW_IP" && "$NEW_IP" != "None" ]] && break
  NEW_IP=""
  sleep "$IP_SLEEP_SECONDS"
done

[[ -n "$NEW_IP" ]] || die "Failed to obtain public IP (check public subnet / IGW / EIP)"
log "Public IP obtained: $NEW_IP"

# Bloque gestionado en ~/.ssh/config
BEGIN_MARK="# BEGIN ${HOST_ALIAS} (managed)"
END_MARK="# END ${HOST_ALIAS} (managed)"

TMP_FILE="$(mktemp)"

# Eliminar bloque previo (compatible macOS/Linux)
awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
  $0==b {inside=1; next}
  $0==e {inside=0; next}
  !inside {print}
' "$SSH_CONFIG_FILE" > "$TMP_FILE"

# Añadir bloque actualizado
{
  printf '\n%s\n' "$BEGIN_MARK"
  printf 'Host %s\n' "$HOST_ALIAS"
  printf '    HostName %s\n' "$NEW_IP"
  printf '    User %s\n' "$SSH_USER"
  printf '    IdentityFile %s\n' "$IDENTITY_FILE"
  printf '    StrictHostKeyChecking accept-new\n'
  printf '    ServerAliveInterval 30\n'
  printf '    ServerAliveCountMax 3\n'
  printf '%s\n' "$END_MARK"
} >> "$TMP_FILE"

# Backup y reemplazo atómico
cp "$SSH_CONFIG_FILE" "$SSH_CONFIG_FILE.bak.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
mv "$TMP_FILE" "$SSH_CONFIG_FILE"
chmod 600 "$SSH_CONFIG_FILE" 2>/dev/null || true

log "Done. Connect using: ssh ${HOST_ALIAS}"
