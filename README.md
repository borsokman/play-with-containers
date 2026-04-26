### play-with-containers

This project provisions a microservices architecture using Docker and Docker Compose. It migrates a multi-tier application into isolated Linux containers running PostgreSQL, RabbitMQ, and Python Flask/Pika services.

## Architecture Overview

- **inventory-db**: PostgreSQL database for the inventory service.
- **billing-db**: PostgreSQL database for the billing service.
- **rabbitmq-server**: Message broker for asynchronous order processing.
- **inventory-app**: REST API managing movies (Internal Port 8080).
- **billing-app**: Message consumer processing orders and writing to the database (Internal Port 8080).
- **api-gateway-app**: Reverse proxy routing requests to appropriate services (Exposed Port 3000).

_All containers are built from scratch using `debian:bullseye` as the base image. No pre-built service images are used._

## Prerequisites

- Linux Operating System (Virtual Machine or Bare Metal)
- Docker Engine
- Docker Compose (V2)

Configuration
Before building the infrastructure, you must create a .env file in the root directory. This file is ignored by Git to prevent credential leaks.

Create .env with the following variables:

# Inventory Database

INVENTORY_DB_NAME=movies_db
INVENTORY_DB_USER=movies_user
INVENTORY_DB_PASSWORD=your_secure_password
INVENTORY_DB_HOST=inventory-db
INVENTORY_DB_PORT=5432

# Billing Database

BILLING_DB_NAME=billing_db
BILLING_DB_USER=orders_user
BILLING_DB_PASSWORD=your_secure_password
BILLING_DB_HOST=billing-db
BILLING_DB_PORT=5432

# RabbitMQ Server

RABBITMQ_HOST=rabbitmq-server
RABBITMQ_PORT=5672
RABBITMQ_USER=billing_user
RABBITMQ_PASSWORD=your_secure_password

# API Gateway Routing

INVENTORY_URL=http://inventory-app:8080

## Infrastructure Setup & Management

The entire infrastructure is managed exclusively via Docker Compose.

To build and start the infrastructure:

docker compose up -d --build

To stop and remove the containers:

docker compose down

To view logs for a specific service:

docker compose logs api-gateway-app

## API Testing with Postman

A Postman Collection (Gateway_API_Tests.postman_collection.json) is included in the repository to automate the audit tests.

Open Postman and click Import.
Select the Gateway_API_Tests.postman_collection.json file.
In the imported collection, go to the Variables tab.
Ensure base_url is set to http://localhost:3000 (or your VM's IP if testing remotely).
Run the requests to verify Inventory CRUD operations and the asynchronous Billing Queue.
Checking billing-db: docker exec -it billing-db psql -d billing_db -c "SELECT \* FROM orders;"

## Project Tree

```
play-with-containers
├─ README.md
├─ docker-compose.yml
├─ play-with-containers API tests.json
├─ play-with-containers-py.png
└─ srcs
   ├─ api-gateway-app
   │  ├─ Dockerfile
   │  ├─ app
   │  │  ├─ __init__.py
   │  │  ├─ config.py
   │  │  └─ routes.py
   │  ├─ requirements.txt
   │  └─ server.py
   ├─ billing-app
   │  ├─ Dockerfile
   │  ├─ app
   │  │  ├─ __init__.py
   │  │  ├─ consumer.py
   │  │  └─ models.py
   │  ├─ requirements.txt
   │  └─ server.py
   ├─ billing-db
   │  ├─ Dockerfile
   │  └─ entrypoint.sh
   ├─ inventory-app
   │  ├─ Dockerfile
   │  ├─ app
   │  │  ├─ __init__.py
   │  │  ├─ models.py
   │  │  └─ routes.py
   │  ├─ requirements.txt
   │  └─ server.py
   ├─ inventory-db
   │  ├─ Dockerfile
   │  └─ entrypoint.sh
   └─ rabbitmq-server
      ├─ Dockerfile
      └─ entrypoint.sh

```
