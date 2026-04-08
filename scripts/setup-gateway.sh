#!/usr/bin/env bash
set -euo pipefail

# 1. Update system and install dependencies
echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv nodejs npm
sudo npm install -g pm2

# 2. Setup Python Virtual Environment (As the vagrant user)
echo "Setting up Python environment..."
APP_DIR="/vagrant/srcs/api-gateway-app"
VENV_DIR="/home/vagrant/.venvs/api-gateway-app"

# Create directories and change ownership to vagrant BEFORE creating the venv
mkdir -p /home/vagrant/.venvs
chown -R vagrant:vagrant /home/vagrant/.venvs

# Run venv creation and pip install as the vagrant user
sudo -u vagrant bash -c "
  python3 -m venv ${VENV_DIR}
  ${VENV_DIR}/bin/pip install --upgrade pip
  ${VENV_DIR}/bin/pip install -r ${APP_DIR}/requirements.txt
"

echo "Creating .env file for Gateway..."
cat <<EOF > ${APP_DIR}/.env
INVENTORY_URL=${INVENTORY_URL}
RABBITMQ_HOST=${RABBITMQ_HOST}
RABBITMQ_PORT=${RABBITMQ_PORT}
RABBITMQ_USER=${RABBITMQ_USER}
RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD}
EOF
chown vagrant:vagrant ${APP_DIR}/.env

# 3. Start the Application with PM2 (As the vagrant user)
echo "Starting Gateway API with PM2..."
sudo -u vagrant bash -c "
  cd ${APP_DIR}
  pm2 delete api-gateway 2>/dev/null || true
  pm2 start server.py --name api-gateway --interpreter ${VENV_DIR}/bin/python
  pm2 save
"

# 4. Configure PM2 to start on boot
echo "Setting up PM2 startup script..."
env PATH=$PATH:/usr/bin /usr/local/bin/pm2 startup systemd -u vagrant --hp /home/vagrant