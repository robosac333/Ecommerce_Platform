#!/bin/bash
set -e
exec > >(tee /var/log/user-data.log) 2>&1

# Update EC2 instance
sudo apt update -y

# Install MySQL client
sudo apt install mysql-client -y

# Install Apache2 Web Server
sudo apt install apache2 -y
    
# Check UFW Firewall Application Profiles
sudo ufw app list

# Start the Apache2 service
sudo systemctl start apache2

# Install PHP and Required Modules
sudo apt install php libapache2-mod-php php-mysql -y

# Configure Apache to Prioritize index.php
sudo sh -c 'echo "<IfModule mod_dir.c>
  DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
</IfModule>" > /etc/apache2/mods-enabled/dir.conf'

# Restart Apache2 Service
sudo systemctl restart apache2

# Clone directly to web root
cd /var/www/html
sudo rm -rf index.html
sudo git clone https://github.com/edaviage/818N-E_Commerce_Application.git .

# Set proper permissions
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/

# Restart Apache
sudo systemctl restart apache2
