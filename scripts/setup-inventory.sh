#!/usr/bin/env bash
set -euo pipefail

# 1. Update system and install dependencies
echo "Installing dependencies..."
apt-get update
apt-get install -y python3 python3-pip python3-venv postgresql postgresql-contrib npm
npm install -g pm2

# 2. Setup PostgreSQL
echo "Setting up PostgreSQL database and user..."
# We can pass the variables directly into SQL commands using psql -c
sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';" || true
sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};" || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};" || true

# 3. Setup Python Virtual Environment (As the vagrant user)
echo "Setting up Python environment..."
APP_DIR="/vagrant/srcs/inventory-app"
VENV_DIR="/home/vagrant/.venvs/inventory-app"

# Create directories and change ownership to vagrant BEFORE creating the venv
mkdir -p /home/vagrant/.venvs
chown -R vagrant:vagrant /home/vagrant/.venvs

# Run venv creation and pip install as the vagrant user
sudo -u vagrant bash -c "
  python3 -m venv ${VENV_DIR}
  ${VENV_DIR}/bin/pip install --upgrade pip
  ${VENV_DIR}/bin/pip install -r ${APP_DIR}/requirements.txt
"

echo "Creating .env file for Inventory..."
cat <<EOF > ${APP_DIR}/.env
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
EOF
chown vagrant:vagrant ${APP_DIR}/.env

# 4. Start the Application with PM2 (As the vagrant user)
echo "Starting Inventory API with PM2..."
sudo -u vagrant bash -c "
  cd ${APP_DIR}
  pm2 delete inventory-api 2>/dev/null || true
  pm2 start server.py --name inventory-api --interpreter ${VENV_DIR}/bin/python
  pm2 save
"

# 5. Configure PM2 to start on boot
echo "Setting up PM2 startup script..."
env PATH=$PATH:/usr/bin /usr/local/bin/pm2 startup systemd -u vagrant --hp /home/vagrant