#######################################
# Makefile for pipeline
# Based on https://github.com/nanounanue/pipeline-template/blob/master/Makefile
########################################

.PHONY: build

PROJECT_NAME:= pipeline

########################################
##              Help                  ##
########################################

help:   ##@Heelp me
	@perl -e '$(HELP_FUN)' $(MAKEFILE_LIST)

########################################
##         Job commands               ##
########################################

volume:##@project Create volume
	@docker network create ${PROJECT_NAME}_net
	@docker volume create --name ${PROJECT_NAME}_store --opt type=none --opt o=bind --opt device=$(CURDIR)/data;
	@touch .data_built

build:  ##@project build project
	@docker-compose --project-name ${PROJECT_NAME} up --force-recreate --build

up:    ##@project Start project
	@docker-compose --project-name ${PROJECT_NAME} up
	@echo airflow running on http://localhost:8082
	@touch .infrastructure_built

stop:  ##@project Stop project
	@docker-compose --project-name ${PROJECT_NAME} stop #Stop services

restart:  ##@project restart project
	@docker-compose --project-name ${PROJECT_NAME} # Restart

logs:
	@docker-compose --project-name ${PROJECT_NAME} logs

local: ##@project install local
	@pip install --editable .

down: ##@project Stop and remove containers, networks, images, and volumes
	@docker-compose --project-name ${PROJECT_NAME} down --volumes

kill: ##@project Kill all docker containers
	@echo "Killing docker-airflow containers"
	@docker kill $(shell docker ps -q --filter docker-airflow)

exec: ##@project interactive session on docker infrastructure
	@docker exec -it ${PROJECT_NAME}_webserver_1 bash

tty:
	@docker exec -i -t $(shell docker ps -q --filter ancestor=puckel/docker-airflow) /bin/bash

sync_up: ##@project sync to s3 bucket, remember to define variable ->  make S3_BUCKET=mybucket
	@aws s3 sync . s3://${S3_BUCKET} --size-only --exclude=".git/*"

sync_down: ##@project sync from s3 bucket, remember to define variable ->  make S3_BUCKET=mybucket
	@aws s3 sync s3://${S3_BUCKET} . --size-only --exclude=".git/*"

clean: clean_images clean_containers clean_data clean_network ##@dependencias

clean_containers:
	@set +e
	@docker-compose --project-name ${PROJECT_NAME} down --volumes --remove-orphans
	@docker-compose --project-name ${PROJECT_NAME} rm -f
	@rm -rf .infrastructure_built || true
	@set -e
clean_images:
	@set +e
	@docker images -a | grep "dpa" | awk  '{print $3}' | xargs docker rmi -f
	#@docker images -a | grep "\-c" | awk  '{print $3}' | xargs docker rmi -f
	#@docker rmi -f $( docker images | grep '^dpa' | awk '{print $3}' )
	@rm -rf .images_built || true
	@set -e
clean_data:
	@set +e
	@docker volume rm ${PROJECT_NAME}_store
	@rm -rf .data_built || true
	@set -e
clean_network: stop
	@set +e
	@docker network rm ${PROJECT_NAME}_net
	@rm -rf .network_built || true
	@set -e

########################################
##            Funciones               ##
##           de soporte               ##
########################################
## NOTE: Tomado de https://gist.github.com/prwhite/8168133 , en particular,
## del comentario del usuario @nowox, lordnynex y @HarasimowiczKamil

## COLORS
BOLD   := $(shell tput -Txterm bold)
GREEN  := $(shell tput -Txterm setaf 2)
WHITE  := $(shell tput -Txterm setaf 7)
YELLOW := $(shell tput -Txterm setaf 3)
RED    := $(shell tput -Txterm setaf 1)
BLUE   := $(shell tput -Txterm setaf 5)
RESET  := $(shell tput -Txterm sgr0)

HELP_FUN = \
    %help; \
    while(<>) { push @{$$help{$$2 // 'options'}}, [$$1, $$3] if /^([a-z0-9_\-]+)\s*:.*\#\#(?:@([a-z0-9_\-]+))?\s(.*)$$/ }; \
    print "uso: make [target]\n\n"; \
    for (sort keys %help) { \
    print "${BOLD}${WHITE}$$_:${RESET}\n"; \
    for (@{$$help{$$_}}) { \
    $$sep = " " x (32 - length $$_->[0]); \
    print "  ${BOLD}${BLUE}$$_->[0]${RESET}$$sep${GREEN}$$_->[1]${RESET}\n"; \
    }; \
    print "\n"; }


"EXECUTABLES ="

TEST_EXEC := $(foreach exec,$(EXECUTABLES),\
				$(if $(shell which $(exec)), some string, $(error "${BOLD}${RED}ERROR${RESET}: No está $(exec) en el PATH, considera revisar Google para instalarlo (Quizá 'apt-get install $(exec)' funcione...)")))

