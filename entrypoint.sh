#!/bin/bash

# Start MySQL
sudo service mysql start

# Start PostgreSQL
sudo service postgresql start

# Set up MySQL root password if not already set (replicates setup_macos.sh logic)
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';" 2>/dev/null || true

# Set up PostgreSQL postgres user if not already set (replicates setup_macos.sh logic)
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres';" 2>/dev/null || true

# Set up Git config from environment variables if provided
if [ ! -z "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
fi
if [ ! -z "$GIT_USER_EMAIL" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
fi

# Execute the CMD
exec "$@"
