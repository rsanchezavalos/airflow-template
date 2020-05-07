# Airflow + docker-compose Sample Repository

## Information
* Based on Python (3.7-slim-buster) official Image [python:3.7-slim-buster](https://hub.docker.com/_/python/) and uses the official [Postgres](https://hub.docker.com/_/postgres/) as backend and [Redis](https://hub.docker.com/_/redis/) as queue
* Install [Docker](https://www.docker.com/)
* Install [Docker Compose](https://docs.docker.com/compose/install/)
* Following the Airflow release from [Python Package Index](https://pypi.python.org/pypi/apache-airflow)

## Installation

Create volumes and project networks

```
$ make volume
```
Build docker compose
```
$ make build
```
Run project
```
$ make up
# Airflow: localhost:8080
```

Interactive session - inside docker container
```
$ make exec
```
Stop containers
```
$ make down
```

## Configuration
airflow config: dags/config/airflow.cfg 

### Python packages
For custom python packages define them in: dags/config/requirements-pip.txt
