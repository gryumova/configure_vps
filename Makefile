# Makefile for deploying Django app on VPS

# Variables
GIT_REPO = https://github.com/gryumova/web3-wallet.git
VENV_DIR = env
PROJECT_DIR = /root/web3-wallet
NGINX_CONFIG = nginx.conf
CELERY_SERVICE = celery.service
DAPHNE_SERVICE= daphne.conf
POSTGRES_DB = wallet
POSTGRES_USER = postgres_user
POSTGRES_PASSWORD = 2608

configure_server:
	sudo apt clean
	sudo apt update 
	sudo apt install -f python3 python3-venv python3-pip nginx redis-server 
	git clone GIT_REPO
	cd $(PROJECT_DIR) 
	python3 -m venv $(VENV_DIR) 
	source $(VENV_DIR)/bin/activate 
	pip install -r requirements.txt

postgresql: 
	sudo apt install postgresql postgresql-contrib
	sudo systemctl start postgresql.service
	sudo -u postgres psql
	CREATE DATABASE $(POSTGRES_DB);
	CREATE USER $(POSTGRES_USER) WITH PASSWORD '$(POSTGRES_PASSWORD)'
	ALTER ROLE $(POSTGRES_USER) SET client_encoding TO 'utf8'
	ALTER ROLE $(POSTGRES_USER) SET default_transaction_isolation TO 'read committed' 
	ALTER ROLE $(POSTGRES_USER) SET timezone TO 'UTC'
	GRANT ALL PRIVILEGES ON DATABASE $(POSTGRES_DB) TO $(POSTGRES_USER)
	\q

# Install Nginx configuration
nginx-conf: 
	sudo cp deploy/$(NGINX_CONFIG) /etc/nginx/sites-available/ 
	sudo ln -s /etc/nginx/sites-available/$(NGINX_CONFIG) /etc/nginx/sites-enabled/ 
	sudo systemctl restart nginx 

celery-conf:
	sudo cp deploy/$(CELERY_SERVICE) /etc/systemd/system/ 
	sudo systemctl daemon-reload 
	sudo systemctl start $(CELERY_SERVICE) 
	sudo systemctl enable $(CELERY_SERVICE) 

redis:
	sudo apt-get update
	sudo apt-get install redis-server
	sudo systemctl start redis

daphne-conf:
	sudo cp deploy/$(DAPHNE_SERVICE) /etc/systemd/system/ 
	sudo systemctl daemon-reload 
	sudo systemctl start $(DAPHNE_SERVICE) 
	sudo systemctl enable $(DAPHNE_SERVICE) 

# Deploy: Install dependencies, collect static files, run migrations, restart Gunicorn and Nginx
deploy: configure_server postgresql migrate nginx-conf daphne-conf redis celery-conf

update:
	sudo systemctl daemon-reload 
	sudo systemctl restart nginx
	sudo systemctl restart daphne
	sudo systemctl restart selery

# Collect static files
collectstatic: 
	python manage.py collectstatic --noinput

# Run database migrations
migrate: 
	cd $(PROJECT_DIR)/project
	python manage.py makemigrations
	python manage.py migrate

# PHONY targets
.PHONY: deploy update collectstatic migrate 


# Makefile Help
help: 
	@echo "configure_server - Install dependencies and packages"
	@echo "collectstatic - Collect static files"
	@echo "migrate - Run database migrations"
	@echo "update - Restart all process" 
	@echo "deploy - Deploy the application (install dependencies, collect static files, migrate, restart Gunicorn and Nginx)"
	@echo "ssh - SSH into the remote server"
	@echo "postgresql - Configure database"
	@echo "daphne-conf- Install daphne configuration"
	@echo "celery-conf - Install Celery configuration"
	@echo "nginx-conf - Install Nginx configuration"
	@echo "help - Display this help message"
