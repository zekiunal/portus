#!/bin/bash

# container names
db_container="portus_db"
web_container="portus_web"
cron_container="portus_cron"
registry_container="portus_registry"

docker rm -f ${registry_container} ${web_container} ${cron_container} ${db_container}
docker system prune -fa

# Default variables
registry_domain="registry.monapi.com"
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
env_tmp_file="config/.env.tmpl"
env_file="config/.env"

# Portus github address
GIT="https://github.com/SUSE/Portus.git"
PORTUS_VER="master"
VERSION=0.2

user_config() {
    local delete="true"
    local ssl="false"

    local registry_domain=$registry_domain
    local aws="n"
    local access_key=$access_key
    local secret=$secret
    local region=$region
    local bucket=$bucket

    local smtp_address=$smtp_address
    local smtp_port=$smtp_port
    local smtp_user_name=$smtp_user_name
    local smtp_password=$smtp_password

    local new_relic=$new_relic

    local port=$port

    local config_ok="n"
    local new_value

    while [[ "$config_ok" == "n" ]]
    do
        if [ ! -z $registry_domain ]
            then
                read -p "Hostname for your Portus? [$registry_domain]: " new_value
            if [ ! -z $new_value ]
                then
                    registry_domain=$new_value
            fi
        fi

        if [ ! -z $port ]
            then
                read -p "Port for your registry? [$port]: " new_value
            if [ ! -z $new_value ]
                then
                    port=$new_value
            fi
        fi

        if [ ! -z $smtp_address ]
            then
                read -p "SMTP server address? [$smtp_address]: " new_value
                if [ ! -z $new_value ]
                    then
                        smtp_address=$new_value
            fi
        fi

        if [ ! -z $smtp_port ]
            then
                read -p "SMTP port? [$smtp_port]: " new_value
                if [ ! -z $new_value ]
                    then
                        smtp_port=$new_value
            fi
        fi

        if [ ! -z $smtp_user_name ]
            then
                read -p "SMTP user name? [$smtp_user_name]: " new_value
                if [ ! -z $new_value ]
                    then
                        smtp_user_name=$new_value
            fi
        fi

        if [ ! -z $smtp_password ]
            then
                read -p "SMTP password? [$smtp_password]: " new_value
                if [ ! -z $new_value ]
                    then
                        smtp_password=$new_value
            fi
        fi

        if [ ! -z $new_relic ]
            then
                read -p "New Relic Key? [$new_relic]: " new_value
                if [ ! -z $new_value ]
                    then
                        new_relic=$new_value
            fi
        fi

        if [ ! -z $aws ]
            then
                read -p "Do you want use AWS S3? [$aws]: " new_value
                if [ ! -z $new_value ]
                    then
                        aws=$new_value
            fi
        fi

        if [ $aws == "y" ]
            then
                if [ ! -z $access_key ]
                    then
                        read -p "Your AWS Access Key? [$access_key]: " new_value
                        if [ ! -z $new_value ]
                            then
                                access_key=$new_value
                    fi
                fi

                if [ ! -z $secret ]
                    then
                        read -p "Your AWS Secret Key? [$secret]: " new_value
                        if [ ! -z $new_value ]
                            then
                                secret=$new_value
                    fi
                fi

                if [ ! -z $region ]
                    then
                        read -p "The AWS region in which your bucket exists? [$region]: " new_value
                        if [ ! -z $new_value ]
                            then
                                region=$new_value
                    fi
                fi

                if [ ! -z $bucket ]
                    then
                        read -p "The bucket name in which you want to store the registry's data? [$bucket]: " new_value
                        if [ ! -z $new_value ]
                            then
                                bucket=$new_value
                    fi
                fi

        fi



        echo -e "\nDoes this look right?\n"
        echo "Hostname          : $registry_domain"
        echo "Port              : $port"




        echo "SMTP address      : $smtp_address"
        echo "SMTP port         : $smtp_port"
        echo "SMTP username     : $smtp_user_name"
        echo "SMTP password     : $smtp_password"

        echo "New Relic         : $new_relic"

        if [ $aws == "y" ]
            then
                echo "AWS Key           : $access_key"
                echo "AWS Secret        : $secret"
                echo "AWS Region        : $region"
                echo "AWS Bucket        : $bucket"
                registry_config_file="config/registry/aws.config.yml"
        else
            registry_config_file="config/registry/config.yml"
        fi

        echo ""
        read -p "ENTER to continue, 'n' to try again, Ctrl+C to exit: " config_ok
    done

    cp $registry_tmp_file   $registry_config_file
    cp $portus_tmp_file     $portus_config_file
    cp $env_tmp_file        $env_file

    sed -i "s/EXTERNAL_IP/$registry_domain/g"                  $registry_config_file
    sed -i "s/REGISTRY_PORT/$port/g"                    $registry_config_file

    if [ $aws == "y" ]
        then
            sed -i "s/AWS_REGION/$region/g"                     $registry_config_file
            sed -i "s/AWS_BUCKET/$bucket/g"                     $registry_config_file
            sed -i "s/AWS_KEY/$access_key/g"                    $registry_config_file
            sed -i "s/AWS_SECRET/$secret/g"                     $registry_config_file
    fi

    sed -i "s/NEW_RELIC/$new_relic/g"                   $registry_config_file

    sed -i "s/SMTP_HOST/$smtp_address/g"        $portus_config_file
    sed -i "s/SMTP_PORT/$smtp_port/g"           $portus_config_file
    sed -i "s/SMTP_USER/$smtp_user_name/g"      $portus_config_file
    sed -i "s/SMTP_PASSWORD/$smtp_password/g"   $portus_config_file
    sed -i "s/SMTP_DOMAIN/$registry_domain/g"          $portus_config_file
    sed -i "s/HOSTNAME/$registry_domain/g"             $portus_config_file
    sed -i "s/DELETE/$delete/g"                 $portus_config_file
    sed -i "s/SSL/$ssl/g"                       $portus_config_file

    sed -i "s/=HOSTNAME/=$registry_domain/g"                       $env_file
    sed -i "s/=REGISTRY_PORT/=$port/g"                      $env_file
}

clean() {
    echo "The setup will destroy the containers used by Portus, removing also their volumes."
    while true; do
        read -p "Are you sure to delete all the data? (Y/N) [Y] " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit 1;;
            "" ) break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

download_portus() {
    echo "Portus clone from GitHub"
    sudo rm -fr portus
    git clone ${GIT} -b ${PORTUS_VER} ${PWD}/portus
}


echo "Portus Installer v${VERSION} Zeki Ünal and contributors."
echo "-------------------------------------------------"

user_config
clean
download_portus