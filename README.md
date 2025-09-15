# 🚀 WordPress Auto Installer Script

This is a **Bash script** that automatically installs and configures **WordPress** on an Ubuntu server with Apache, PHP, and MySQL.

## ✨ Features
- Installs **Apache2, PHP, and required PHP extensions**
- Supports both **external MySQL databases** and **local MySQL installation**
- Automatically **creates MySQL database and user**
- Downloads and configures the **latest WordPress**
- Prompts for **custom WordPress folder name**
- Updates `wp-config.php` with database credentials
- Lets you set a **custom table prefix** (default: `wp_`)
- Sets **correct permissions** for WordPress

## 📦 Requirements
- Ubuntu server (20.04+ recommended)
- `curl` installed (`sudo apt install curl -y`)

## 🔧 Usage
Clone the repository and run the script:

```bash
git clone https://github.com/YOUR_USERNAME/wordpress-installer.git
cd wordpress-installer
chmod +x wordpress-install.sh
./wordpress-install.sh