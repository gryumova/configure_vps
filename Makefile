# Makefile for deploying Django app on VPS

# Variables
GIT_REPO = https://github.com/gryumova/web3-wallet
VENV_DIR = /root/web3-wallet/env
PROJECT_DIR = /root/web3-wallet
NGINX_CONFIG = db6a934f5372.vps.myjino.ru.conf
CELERY_SERVICE = celery.service
DAPHNE_SERVICE= daphne.conf
POSTGRES_DB = wallet
POSTGRES_USER = postgres_user
POSTGRES_PASSWORD = 2608

configure_server:
	sudo apt clean
	sudo apt update && sudo apt upgrade
	sudo apt-get update --fix-missing 
	sudo apt install -f python3 python3-venv python3-pip nginx redis-server 

clone_repo:
	git clone $(GIT_REPO) /root/web3-wallet 
	cd $(PROJECT_DIR) 
	python3 -m venv $(VENV_DIR) 
	bash -c "source /root/web3-wallet/env/bin/activate" 
	pip install -r /root/web3-wallet/project/requirements.txt
	pip install django
	pip install daphne
	pip install django-cors-headers
	pip install djangorestframework
	pip install psycopg2-binary web3
	pip install channels
	pip install django_extensions django_celery_beat
	pip install celery[redis]

postgresql: 
	# sudo apt install postgresql postgresql-contrib
	# sudo systemctl start postgresql.service
	# sudo -u postgres psql -c "CREATE DATABASE $(POSTGRES_DB);"
	sudo -u postgres psql -c "CREATE USER $(POSTGRES_USER) WITH PASSWORD '$(POSTGRES_PASSWORD)';"
	sudo -u postgres psql -c "ALTER ROLE $(POSTGRES_USER) SET client_encoding TO 'utf8';"
	sudo -u postgres psql -c "ALTER ROLE $(POSTGRES_USER) SET default_transaction_isolation TO 'read committed';" 
	sudo -u postgres psql -c "ALTER ROLE $(POSTGRES_USER) SET timezone TO 'UTC';"
	sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $(POSTGRES_DB) TO $(POSTGRES_USER);"

# Install Nginx configuration
nginx-conf:
	sudo mkdir -p /etc/nginx/sites-enabled/ 
	sudo mkdir -p /etc/nginx/sites-available/ 
	sudo cp deploy/nginx.conf /etc/nginx/sites-available/$(NGINX_CONFIG) 
	sudo ln -s /etc/nginx/sites-available/$(NGINX_CONFIG) /etc/nginx/sites-enabled/ 
	sudo systemctl restart nginx 

celery-conf:
	sudo cp deploy/$(CELERY_SERVICE) /etc/systemd/system/celery.service
	sudo systemctl daemon-reload 
	sudo systemctl start $(CELERY_SERVICE) 
	sudo systemctl enable $(CELERY_SERVICE) 

redis:
	sudo apt-get update
	sudo apt-get install redis-server
	sudo systemctl start redis

daphne-conf:
	sudo apt-get update
	sudo apt-get install supervisor
	sudo cp deploy/$(DAPHNE_SERVICE) /etc/supervisor/conf.d/daphne.conf
	sudo service supervisor restart
	sudo supervisorctl status 

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
	python3 $(PROJECT_DIR)/project/manage.py makemigrations
	python3 $(PROJECT_DIR)/project/manage.py migrate

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
