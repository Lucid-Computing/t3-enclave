#!/bin/bash
# Install the measured SSH keys for root, then hand off to systemd.
#
# SSH_KEYS is set inline in tinfoil-config.yml, so the authorized keys are
# covered by the attestation rather than supplied at deploy time.
set -euo pipefail

fail() { printf 'pathfinder-cvm: %s\n' "$*" >&2; exit 1; }

[[ $$ == 1 ]] || fail 'the entrypoint must run as PID 1'

umask 077
printf '%s\n' "${SSH_KEYS:?SSH_KEYS is required}" > /run/authorized_keys
ssh-keygen -lf /run/authorized_keys >/dev/null 2>&1 || fail 'SSH_KEYS has no usable public key'
unset SSH_KEYS
umask 022

printf '%s\n' "${WORKSPACE_HOSTNAME:-pathfinder-cvm}" > /etc/hostname
hostname "$(cat /etc/hostname)"

ssh-keygen -A
exec /sbin/init
