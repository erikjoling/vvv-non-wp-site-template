#!/usr/bin/env bash
# Provision a non-wordpress website

# Setup Website
# Create custom website or import existing one. Currently no database support 
#
# If you want to import have your website at `/www/imports/${VVV_SITE_NAME}/`
#
# Process:
# 1. Database
# 2. Website Files
# 3. NGINX Server

# Get the first host specified in vvv-custom.yml. Fallback: <site-name>.test
DOMAIN=`get_primary_host "${VVV_SITE_NAME}".test`

# Get the hosts specified in vvv-custom.yml. Fallback: DOMAIN value
DOMAINS=`get_hosts "${DOMAIN}"`

# Get the database name specified in vvv-custom.yml. Fallback: site-name
DB_NAME=`get_config_value 'db_name' "${VVV_SITE_NAME}"`
DB_NAME=${DB_NAME//[\\\/\.\<\>\:\"\'\|\?\!\*-]/}

# Site import
SITE_IMPORT="/srv/www/imports/${VVV_SITE_NAME}"

#
# START
#
echo -e "\nStart setup website..."

#
# 1. DATABASE
#

# Make a database, if we don't already have one
echo -e "\nCreating database '${DB_NAME}' (if it's not already there)"
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME}"
mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO wp@localhost IDENTIFIED BY 'wp';"
echo -e "\n DB operations done.\n\n"

#
# 2. WEBSITE FILES
#

# Only import if there is no website
if [[ ! -f "${VVV_PATH_TO_SITE}/public_html/index.php" ]] && [[ ! -f "${VVV_PATH_TO_SITE}/public_html/index.html" ]]; then

    # Copy the files from 
    echo "Importing website from '${SITE_IMPORT}'"
    echo "Depending on the size of the website this could take a while..."
    cp -r "${SITE_IMPORT}" "${VVV_PATH_TO_SITE}/"

    # Rename directory to `public_html`
    mv "${VVV_PATH_TO_SITE}/${VVV_SITE_NAME}" "${VVV_PATH_TO_SITE}/public_html" 
    
    # If .htaccess exists: Backup and remove
    if [[ -f "${VVV_PATH_TO_SITE}/public_html/.htaccess" ]]; then        
        echo "Backing up .htaccess"
        mv "${VVV_PATH_TO_SITE}/public_html/.htaccess" "${VVV_PATH_TO_SITE}/public_html/.htaccess-backup"
    fi

else
    echo -e "\nSetup website..."
    mkdir "${VVV_PATH_TO_SITE}/public_html" 
fi

#
# 3. NGINX SERVER
#

# Setup logs
if [[ ! -d "${VVV_PATH_TO_SITE}/provision/log" ]]; then
    # Nginx Logs
    echo "Setting up logs..."
    mkdir -p ${VVV_PATH_TO_SITE}/log
    touch ${VVV_PATH_TO_SITE}/log/error.log
    touch ${VVV_PATH_TO_SITE}/log/access.log
fi

# Setup configuration
if [[ ! -f "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf" ]]; then

    # Nginx Configuration
    echo "Setting up configuration..."
    cp -f "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf.tmpl" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"

    # SSL/TLS
    echo "Setting up ssl/tls..."
    if [ -n "$(type -t is_utility_installed)" ] && [ "$(type -t is_utility_installed)" = function ] && `is_utility_installed core tls-ca`; then
        sed -i "s#{{TLS_CERT}}#ssl_certificate /vagrant/certificates/${VVV_SITE_NAME}/dev.crt;#" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
        sed -i "s#{{TLS_KEY}}#ssl_certificate_key /vagrant/certificates/${VVV_SITE_NAME}/dev.key;#" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
    else
        sed -i "s#{{TLS_CERT}}##" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
        sed -i "s#{{TLS_KEY}}##" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
    fi

else
    echo -e "\nSkip setting up NGINX..."
fi

