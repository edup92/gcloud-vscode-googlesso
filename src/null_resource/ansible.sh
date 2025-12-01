#!/usr/bin/env bash
set -euo pipefail

IP="$INSTANCE_IP"
INSTANCE_ID="$INSTANCE_ID"
SG_MAIN="$SG_MAIN_ID"
SG_TEMP="$SG_TEMPSSH_ID"
SSH_KEY="$SSH_KEY"
VARS_FILE="$VARS_FILE"

# Asignar Security Group temporal para SSH
echo "Assigning temporary SSH security group: $SG_TEMP"

aws ec2 modify-instance-attribute \
    --instance-id "$INSTANCE_ID" \
    --groups "$SG_TEMP"

echo "Temporary SG applied."

echo "Waiting for instance SSH"

OK=0
for i in {1..14}; do
  ssh -o BatchMode=yes \
      -o ConnectTimeout=3 \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -i "$SSH_KEY" \
      ubuntu@"$IP" 'exit' >/dev/null 2>&1 && {
        echo "SSH available."
        OK=1
        break
      }
  echo "Instance SSH unavailable, retrying..."
  sleep 5
done

if [ "$OK" -ne 1 ]; then
  echo "ERROR: Instance unreachable, restoring main SG..."
  aws ec2 modify-instance-attribute \
      --instance-id "$INSTANCE_ID" \
      --groups "$SG_MAIN"
  exit 1
fi

# Ejecutar Ansible
ansible-playbook \
  -i "$IP," \
  --user ubuntu \
  --private-key "$SSH_KEY" \
  --extra-vars "@$VARS_FILE" \
  --ssh-extra-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
  "$PLAYBOOK_PATH"

# Restaurar SG principal
echo "Restoring main security group: $SG_MAIN"

aws ec2 modify-instance-attribute \
    --instance-id "$INSTANCE_ID" \
    --groups "$SG_MAIN"

# Marking as installed

echo "Settign as installed in SSM: $SSM_PARAM_NAME"

aws ssm put-parameter \
  --name "${SSM_PARAM_NAME}" \
  --value "$(date +%s)" \
  --type String \
  --overwrite

echo "DONE"