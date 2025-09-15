#!/bin/bash

# Function to check and install packages
check_and_install() {
    if ! dpkg -s "$1" &> /dev/null; then
        echo "Installing $1..."
        sudo apt install "$1" -y
    else
        echo "$1 is already installed."
    fi
}

# 1. Update package list
echo "🔄 Updating package list..."
sudo apt update

# 2. Check and install Apache
check_and_install apache2

# 3. Check and install PHP and required extensions
php_packages=(
    php php-mysql libapache2-mod-php php-cli php-curl php-gd
    php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip
)
for pkg in "${php_packages[@]}"; do
    check_and_install "$pkg"
done

# 4. Ask user if they want to use an external MySQL database or install local MySQL
read -p "Do you want to use an external MySQL database? (y/n): " use_external_db

if [[ "$use_external_db" =~ ^[Yy]$ ]]; then
    # External DB access input
    read -p "Enter External MySQL Server IP or Hostname: " DB_HOST
    read -p "Enter MySQL Database Name: " DB_NAME
    read -p "Enter MySQL User Name: " DB_USER
    read -p "Enter MySQL Password: " DB_PASS
    DB_SETUP=true
else
    # Proceed with local MySQL installation and setup
    read -p "Do you want to install MySQL server and client? (y/n): " install_mysql

    if [[ "$install_mysql" =~ ^[Yy]$ ]]; then
        # Check and install MySQL client
        if ! command -v mysql &> /dev/null; then
            echo "Installing MySQL client..."
            check_and_install mysql-client
        else
            echo "MySQL client is already installed."
        fi

        # Check and install MySQL server
        if ! dpkg -s mysql-server &> /dev/null; then
            echo "Installing MySQL server..."
            sudo apt install mysql-server -y
            sudo systemctl enable mysql
            sudo systemctl start mysql
        else
            echo "MySQL server is already installed."
        fi

        # Ensure MySQL is running
        if ! pgrep mysql > /dev/null; then
            echo "Starting MySQL server..."
            sudo systemctl start mysql
        fi

        # Prompt for database credentials
        read -p "Enter MySQL Database Name: " DB_NAME
        read -p "Enter MySQL User Name: " DB_USER
        read -p "Enter MySQL Password: " DB_PASS
        echo

        # Create database and user
        echo "🛠️ Creating MySQL database and user..."
        sudo mysql <<EOF
CREATE DATABASE \`$DB_NAME\`;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

        DB_HOST="localhost"
        DB_SETUP=true
    else
        echo "❌ Skipping MySQL installation and configuration."
        DB_SETUP=false
    fi
fi

# 10. Download WordPress
cd /tmp
echo "⬇️ Downloading WordPress..."
curl -O https://wordpress.org/latest.tar.gz
tar -xvzf latest.tar.gz

# 11. Ask for folder rename
read -p "Enter a name for your WordPress folder (e.g., mysite): " WP_FOLDER

# 12. Move and set permissions
sudo mv wordpress "/var/www/html/$WP_FOLDER"
sudo chown -R www-data:www-data "/var/www/html/$WP_FOLDER"
sudo chmod -R 755 "/var/www/html/$WP_FOLDER"

# 13. Copy and edit wp-config.php if DB was setup
cd "/var/www/html/$WP_FOLDER"
sudo cp wp-config-sample.php wp-config.php

if [ "$DB_SETUP" = true ]; then
    echo "⚙️ Updating wp-config.php with DB info..."
    sudo sed -i "s/database_name_here/$DB_NAME/" wp-config.php
    sudo sed -i "s/username_here/$DB_USER/" wp-config.php
    sudo sed -i "s/password_here/$DB_PASS/" wp-config.php

    # Update DB_HOST in wp-config.php (default is 'localhost')
    sudo sed -i "s/'localhost'/'$DB_HOST'/" wp-config.php
fi

# 14. Ask user for table prefix
read -p "Enter your desired WordPress table prefix (default: wp_): " WP_PREFIX
WP_PREFIX=${WP_PREFIX:-wp_}  # fallback if user presses enter

# Update table prefix in wp-config.php
sudo sed -i "s/^\(\$table_prefix\s*=\s*\).*/\1'$WP_PREFIX';/" wp-config.php

# 15. Finish
echo "✅ WordPress setup completed at: /var/www/html/$WP_FOLDER"
echo "🌐 You can now access it in your browser."

#16. Again set folder permission
sudo chown -R www-data:www-data "/var/www/html/$WP_FOLDER"
sudo chmod -R 755 "/var/www/html/$WP_FOLDER"

if [ "$DB_SETUP" = true ]; then
    echo "🗄️ Database Host: $DB_HOST"
    echo "🗄️ Database Name: $DB_NAME"
    echo "👤 Database User Name: $DB_USER"
    echo "🔑 Database User Password: $DB_PASS"
else
    echo "⚠️ MySQL not configured. You need to manually configure wp-config.php."
fi

echo "📂 Table Prefix: $WP_PREFIX"
