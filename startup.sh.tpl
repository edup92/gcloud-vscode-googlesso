#!/bin/bash
set -e

apt-get update -y
apt-get install -y ansible git curl
rm -rf /home/vscode/gcloud-vscode-googlesso
git clone https://github.com/edup92/gcloud-vscode-googlesso.git /home/vscode/gcloud-vscode-googlesso
cat > /home/vscode/gcloud-vscode-googlesso/vars.json <<EOF
{
  "project_name": "${project_name}",
  "gcloud_project_id": "${gcloud_project_id}",
  "gcloud_region": "${gcloud_region}",
  "domain": "${domain}",
  "admin_email": "${admin_email}",
  "allowed_countries": ${allowed_countries},
  "oauth_client_id": "${oauth_client_id}",
  "oauth_client_secret": "${oauth_client_secret}"
}
EOF
chown vscode:vscode /home/vscode/gcloud-vscode-googlesso/vars.json
ansible-playbook /home/vscode/gcloud-vscode-googlesso/playbook.yml --connection=local -e @/home/vscode/gcloud-vscode-googlesso/vars.json
rm -rf /home/vscode/gcloud-vscode-googlesso
