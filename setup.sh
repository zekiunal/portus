#!/bin/bash

# container names
db_container="portus_db"
web_container="portus_web"
cron_container="portus_cron"
registry_container="portus_registry"

docker rm -f ${registry_container} ${web_container} ${cron_container} ${db_container}
docker system prune -fa

# Default variables
hostname="registry.monapi.com"
port="5000"
registry_http_secret=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 32)

# AWS S3 Setting Default variables
access_key="AWS_KEY"
secret="AWS_SECRET"
region="eu-central-1"
bucket="bucket.registry.domain.com"

# SMTP Settings
smtp_address="smtp.elasticemail.com"
smtp_port="587"
smtp_user_name="social@monapi.com"
smtp_password="90be52d4-58e6-4109-93ed-9ae9d8aac7d"

# New Relic Settings
new_relic="916a6593baf44f256c9835b90b622b410ac1248"

# config files
registry_config_file="config/registry/config.yml"
registry_tmp_file="config/registry/config.yml.tmpl"
registry_crt_file="config/registry/portus.crt"
portus_config_file="config/web/config.yml"
portus_tmp_file="config/web/config.yml.tmpl"

# Portus github address
GIT="https://github.com/SUSE/Portus.git"
PORTUS_VER="master"
VERSION=0.2

user_config() {
    echo "User Config"
}

echo "Portus Installer v${VERSION} Zeki Ünal and contributors."
echo "-------------------------------------------------"
