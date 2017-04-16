#!/bin/bash
docker rm -f portus_registry portus_web portus_cron portus_db
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

# container names
db_container="portus_db"
web_container="portus_web"
cron_container="portus_cron"
registry_container="portus_registry"

# Portus github address
GIT="https://github.com/SUSE/Portus.git"
PORTUS_VER="v2.2"
VERSION=0.1
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

database_up() {
    echo "Database service create"
    docker rm -f ${db_container}
    rm -fr /mysql/data
    docker run -d --name ${db_container} -v /mysql/data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD="portus" library/mariadb:10.0.23
    sleep 10
}

web_build() {
    echo "Portus Web Building"
    cp $portus_config_file portus/config/config.yml
    #cd portus && docker build --no-cache -t ${web_container} .
    cd portus && docker build -t ${web_container} .
    cd /portus_setup
}

web_up() {
    echo "Portus Web up"
    docker rm -f ${web_container}
    docker run -d --link ${db_container} --name ${web_container} \
        -v ${PWD}/portus:/portus \
        -p 3000:3000 \
        -e PORTUS_MACHINE_FQDN_VALUE=${hostname} \
        -e PORTUS_DB_HOST=${db_container} \
        -e PORTUS_DB_PASSWORD=portus \
        -e PORTUS_PUMA_HOST=0.0.0.0:3000 \
        -e PORTUS_PUMA_WORKERS=2 \
        -e PORTUS_PUMA_MAX_THREADS=4 \
        ${web_container} pumactl -F /portus/config/puma.rb start
}

cron_up() {
    echo "Portus Crone up"
    docker rm -f ${cron_container}
    docker run -d --link ${db_container} --name ${cron_container} \
        -v ${PWD}/portus:/portus \
        --entrypoint="bin/crono" \
        -e PORTUS_MACHINE_FQDN_VALUE=${hostname} \
        -e PORTUS_DB_HOST=${db_container} \
        -e PORTUS_DB_PASSWORD=portus \
        ${web_container}
}

registry_up() {
    echo "Portus Registry up"
    docker rm -f ${registry_container}
    docker run -d --link ${web_container} --name ${registry_container} \
        -v ${PWD}/config/registry/portus.crt:/etc/docker/registry/portus.crt:ro \
        -v ${PWD}/config/registry/config.yml:/etc/docker/registry/config.yml:ro \
        -v /registry_data:/registry_data \
        -p 5001:5001 -p 5000:5000 \
        -e REGISTRY_AUTH_TOKEN_REALM=http://${hostname}:3000/v2/token \
        -e REGISTRY_AUTH_TOKEN_SERVICE=${hostname}:${port} \
        -e REGISTRY_AUTH_TOKEN_ISSUER=${hostname} \
        library/registry:2.3.1
}

user_config() {
    local delete="true"
    local ssl="false"

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

    local port=5000

    local config_ok="n"
    local new_value=""

    while [[ "$config_ok" == "n" ]]
    do
        if [ ! -z $hostname ]
            then
                read -p "Hostname for your Portus? [$hostname]: " new_value
            if [ ! -z $new_value ]
                then
                    hostname=$new_value
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
        echo "Hostname          : $hostname"
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

    cp $registry_tmp_file $registry_config_file
    cp $portus_tmp_file $portus_config_file

    sed -i "s/EXTERNAL_IP/$hostname/g"                  $registry_config_file
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
    sed -i "s/SMTP_DOMAIN/$hostname/g"          $portus_config_file
    sed -i "s/HOSTNAME/$hostname/g"             $portus_config_file
    sed -i "s/DELETE/$delete/g"                 $portus_config_file
    sed -i "s/SSL/$ssl/g"                       $portus_config_file
}

echo "Portus Installer v${VERSION} Zeki Ünal and contributors."
echo "-------------------------------------------------"

user_config
clean
database_up
download_portus
web_build
web_up
cron_up
registry_up

docker run --rm --link ${db_container}  -e PORTUS_MACHINE_FQDN_VALUE=${hostname} -e PORTUS_DB_HOST=${db_container} ${web_container} rake db:migrate:reset  > /dev/null
docker run --rm --link ${db_container}  -e PORTUS_MACHINE_FQDN_VALUE=${hostname} -e PORTUS_DB_HOST=${db_container} ${web_container} rake db:seed  > /dev/null
