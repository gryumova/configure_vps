# VPS Configuration for Django ASGI Project Deployment with PostgreSQL

This repository provides a streamlined setup for deploying a Django ASGI project with a PostgreSQL database on a Jino VPS (Virtual Private Server).

## Initial Setup

To get started, follow these steps:

1. **Configure Paths**: Within the `deploy` directory, ensure to update the absolute paths to the working directory and virtual environments in all relevant files.

2. **Update Makefile**: Modify the Makefile as follows:
    - Change the link to the repository of your project.
    - Update the path to the working directory on the remote server.
    - Specify the host where the server is located.
    - Provide details about the PostgreSQL database. Adjust as needed.

## Installation

Clone this repository onto your remote server and execute the following commands:

### Install Dependencies

Install necessary packages and applications:

```bash
make configure_server
```

### Clone Project Repository

Clone your project repository and prepare it for deployment:

```bash
make clone_repo 
```

### PostgreSQL Configuration

Configure the PostgreSQL database with the credentials specified in the Makefile. Make changes if required:

```bash
make postgresql 
```

### Nginx Setup

Start the Nginx server:

```bash
make migrate 
make nginx-conf
```

### Daphne, Redis, and Celery Configuration

Configure Daphne, Redis, and Celery for ASGI support and background tasks:

```bash
make daphne-conf 
make redis
make celery-conf
```

## Conclusion

By following these steps, you can efficiently set up your VPS for deploying your Django ASGI project with a PostgreSQL database. Make sure to review and update configurations as needed for your specific project requirements. Enjoy deploying your application with ease!