# ----------------
# Make help script
# ----------------

# Usage:
# Add help text after target name starting with '\#\#'
# A category can be added with @category. Team defaults:
# 	dev-environment
# 	docker
# 	test

# Output colors
GREEN  := $(shell tput -Txterm setaf 2)
WHITE  := $(shell tput -Txterm setaf 7)
YELLOW := $(shell tput -Txterm setaf 3)
RESET  := $(shell tput -Txterm sgr0)

# Script
HELP_FUN = \
	%help; \
	while(<>) { push @{$$help{$$2 // 'options'}}, [$$1, $$3] if /^([a-zA-Z0-9\-]+)\s*:.*\#\#(?:@([a-zA-Z0-9\-]+))?\s(.*)$$/ }; \
	print "usage: make [target]\n\n"; \
	for (sort keys %help) { \
	print "${WHITE}$$_:${RESET}\n"; \
	for (@{$$help{$$_}}) { \
	$$sep = " " x (32 - length $$_->[0]); \
	print "  ${YELLOW}$$_->[0]${RESET}$$sep${GREEN}$$_->[1]${RESET}\n"; \
	}; \
	print "\n"; }

help:
	@perl -e '$(HELP_FUN)' $(MAKEFILE_LIST) $(filter-out $@,$(MAKECMDGOALS))

## Environment variables for the Makefile -- do not change unless you understand the impact.
phpcs_config = --ignore=*.css,*.min.js,*features.*.inc,*.svg,*.jpg,*.png,*.json,*.woff*,*.ttf,*.md,*.sh,AltTextBehavior.class.php
project_root = /var/www/html
custom_module_location = $(project_root)/docroot/modules/custom/
custom_theme_location = $(project_root)/docroot/themes/custom/
coder_sniffer_path = $(project_root)/vendor/drupal/coder/coder_sniffer
DIR = ${pwd}

## Project Specific environment variables -- modify on a project specific basis.
PROJECT_NAME = drupal
drush_alias = @drupal.local
uuid = "4d940caa-9d31-4f7e-bb5c-b4fb5bd86905"
SITE_NAME = "Drupal"

phpcs:  ##@testing Run CodeSniffer coding standards checks
	@clear
	@clear
	@docker-compose exec -T php $(project_root)/bin/phpcs --config-set installed_paths $(coder_sniffer_path)
	@docker-compose exec -T php $(project_root)/bin/phpcs --standard=Drupal $(custom_module_location) $(custom_theme_location) $(phpcs_config)

phpcbf:  ##@testing Automatically correct Coding Standards Violations
	@docker-compose exec -T php $(project_root)/bin/phpcbf --config-set installed_paths $(coder_sniffer_path)
	@docker-compose exec -T php $(project_root)/bin/phpcbf --standard=Drupal $(custom_module_location) $(custom_theme_location) $(phpcs_config)

behat:  ##@testing Execute Behat Test Suite
ifdef TRAVIS
	@docker-compose exec -T php $(project_root)/bin/behat -c $(project_root)/tests/behat/behat.yml --tags=~@skip --colors -f progress
else
	@docker-compose exec -T php $(project_root)/bin/behat -c $(project_root)/tests/behat/behat.yml --tags=~@skip --colors
endif

behat-wip: ##@testing Execute Behat Tests tagged with @wip
	docker-compose exec -T php $(project_root)/bin/behat -c $(project_root)/tests/behat/behat.yml --tags=@wip --colors -f progress

wcag2AA:  ##@testing Running Pa11y-CI tool for wcag2AA compliance against URLS in tests/pa11y/config.json
	@docker-compose run pa11y /bin/bash -c "pa11y-ci --config /workspace/wcag2-config.json"

wcag2AA-url: ##@testing Running Pa11y-CI tool for wcag2AA compliance against a specified URL passed as a parameter
	@docker-compose run pa11y /bin/bash -c "pa11y-ci $(filter-out $@,$(MAKECMDGOALS))"

phpunit:  ##@testing Running Drupal Unit tests
	@docker-compose exec -T php $(project_root)/bin/phpunit -c $(project_root)/phpunit.xml.dist

test:  ##@testing Execute all test suites
	@make phpcs
	@make scan-custom-deprecated
	#@make fetest
	#@make phpunit
	@make behat
	@make wcag2AA

devinit: ##@initialize Initialize development environment
	@clear
	@make docker-up
	@make composer-install
	@sleep 5
	@docker-compose exec php /bin/bash -c "mkdir -p $(project_root)/docroot/sites/default/files/private"
	@make profile-setup
	#@make import-config
	#@make fetools
	#@make febuild
	#@make entup
	@make updb
	@make log-sanitize
	@docker-compose exec php $(project_root)/bin/drush $(drush_alias) sset system.maintenance_mode 0
	@make cache-reset

devsetup: ##@initialize Set up dev environment (existing database)
	@clear
	@make docker-up
	@make composer-install
	@sleep 5
	@docker-compose exec php /bin/bash -c "mkdir -p $(project_root)/docroot/sites/default/files/private"
	@docker-compose exec php /bin/bash -c "mkdir -p $(project_root)/docroot/sites/default/files/private/api_logs"
	@make files-symlink
	#@make import-config
	#@make fetools
	#@make febuild
	#@make entup
	@make updb
	@make log-sanitize
	@docker-compose exec php $(project_root)/bin/drush $(drush_alias) sset system.maintenance_mode 0
	@make cache-reset

devclean: ##@initialize Halts Docker and deletes project related volumes (destroys database and drupal install)
	@clear
	@docker-compose down --volumes
	@docker volume ls

fetools: ##@initialize Builds the front end tools inside the fetools container
	@docker-compose run --rm fetools /bin/bash -c "npm install"

export-config: ##@drush Export Configuration Manager yaml files
	@docker-compose exec php $(project_root)/bin/drush $(drush_alias) cex -y
	@docker-compose exec php $(project_root)/bin/drush $(drush_alias) csex dev -y

import-config: ##@drush Import Configuration Manager yaml files
	@docker-compose exec php $(project_root)/bin/drush $(drush_alias) cim vcs -y
	@docker-compose exec php $(project_root)/bin/drush $(drush_alias) csim dev -y

composer-install: ##@composer Run Composer Install
ifdef TRAVIS
	@docker-compose -f docker-compose.yml -f docker-compose-travis.yml exec php composer install --working-dir=$(project_root)
else
	@docker-compose exec php composer install --working-dir=$(project_root)
endif

composer-update: ##@composer Run Composer Update
	@docker-compose exec php composer update --working-dir=$(project_root)

docker-up: ##@docker Run Docker Compose Up
ifdef TRAVIS
	@docker-compose -f docker-compose.yml -f docker-compose-travis.yml up -d --build
else
	@docker-compose up -d --build
endif
docker-down: ##@docker Run Docker Compose down
ifdef TRAVIS
	@docker-compose -f docker-compose.yml -f docker-compose-travis.yml down
else
	@docker-compose down
endif

log: ##@docker Tails PHP logs
	@docker-compose logs -f -t php

log-errors: ##@docker Tails PHP logs with output limited to errors.
	@docker-compose logs -f -t php | grep Error

log-sanitize: ##@drush Runs wd-del removing info log messages
	@docker-compose exec php $(project_root)/bin/drush $(drush_alias) wd-del --severity=Info -y

fewatch: ##@tools Runs front end watch process inside the fetools container
	@docker-compose run --rm fetools /bin/bash -c "gulp watch"

febuild: ##@tools Runs front end build process inside the fetools container
	@docker-compose run --rm fetools /bin/bash -c "gulp default"

fetest: ##@testing Runs front end linting process inside the fetools container
	@docker-compose run --rm fetools /bin/bash -c "gulp test"

cache-reset: ##@drush run drush cache-reset
ifdef TRAVIS
	@docker-compose -f docker-compose.yml -f docker-compose-travis.yml exec php $(project_root)/bin/drush $(drush_alias) cr
else
	@docker-compose exec php $(project_root)/bin/drush $(drush_alias) cr
endif

entup: ##@drush run drush entup from Devel module
	@docker-compose exec php $(project_root)/bin/drush $(drush_alias) entup -y

updb: ##@drush run drush updb
	@docker-compose exec php $(project_root)/bin/drush $(drush_alias) updb -y

uli: ##@drush run drush updb
	@docker-compose exec php $(project_root)/bin/drush $(drush_alias) uli -y

build-artifact:  ##@deploy Build artifact for Acquia Deployment
	@./scripts/build-artifact.sh $(filter-out $@,$(MAKECMDGOALS))

import-db: ##@initialize Import DB downloaded from Acquia Cloud
	# Importing database.
ifdef TRAVIS
	@echo "Downloading seed database to travis..."
	@aws s3 cp s3://travis-ci-build-files/$(PROJECT_NAME)/db/database.sql.gz ${HOME}/build/promet/$(PROJECT_NAME)/config/db/database.sql.gz
	@echo "Unzipping newly downloaded database..."
	@if [ -f ${HOME}/build/promet/$(PROJECT_NAME)/config/db/database.sql.gz ]; then gunzip ${HOME}/build/promet/$(PROJECT_NAME)/config/db/database.sql.gz -f; fi
	@echo "Importing newly downloaded database..."
	@if command -v pv >/dev/null; then pv ${HOME}/build/promet/$(PROJECT_NAME)/config/db/database.sql | docker-compose exec -T db mysql -udrupal -pdrupal drupal; else docker-compose exec -T db mysql -udrupal -pdrupal drupal < ${HOME}/build/promet/$(PROJECT_NAME)/config/db/database.sql; fi
else
	@echo "Downloading seed database from S3..."
	@aws s3 cp --profile=travis-ci s3://travis-ci-build-files/$(PROJECT_NAME)/db/database.sql.gz ./config/db/database.sql.gz
	@if [ ! -f ./config/db/database.sql.gz ]; then echo "Please place a copy of the database in ./config/db/, and name the file database.sql.gz."; exit 1; fi
	@if [ -f ./config/db/database.sql.gz ]; then gunzip ./config/db/database.sql.gz -f; fi
	@echo "Dropping current database..."
	@docker-compose exec -T php $(project_root)/bin/drush $(drush_alias) sql-drop -y
	@echo "Importing newly downloaded seed database..."
	@if command -v pv >/dev/null; then pv ./config/db/database.sql | docker-compose exec -T db mysql -udrupal -pdrupal drupal; else docker-compose exec -T db mysql -udrupal -pdrupal drupal < ./config/db/database.sql; fi
endif

import-files: ##@initialize Download the files directory from Acquia Cloud
ifndef TRAVIS
	@echo "Downloading files directory from S3..."
	@aws s3 cp --profile=travis-ci s3://travis-ci-build-files/$(PROJECT_NAME)/files/files.tar.gz ./config/files/files.tar.gz
	@docker-compose exec php /bin/bash -c "chmod a+w $(project_root)/docroot/sites/default"
	@docker-compose exec php /bin/bash -c "cd $(project_root)/docroot; tar -xvzf ../config/files/files.tar.gz"
endif

sync-to-s3: ##@deploy Sync local DB and files tarball to S3
	@echo "Syncing local databases to S3..."
	@aws s3 sync --profile=travis-ci ./config/db s3://travis-ci-build-files/$(PROJECT_NAME)/db
	@echo "Syncing local files tarball..."
	@aws s3 cp --profile=travis-ci ./config/files/files.tar.gz s3://travis-ci-build-files/$(PROJECT_NAME)/files/files.tar.gz

sanitize-db: #dev-environment Sanitize the database.
	# Sanitize database.
	@echo "Sanitizing database for $(PROJECT_NAME)..."
	@docker-compose exec -T php $(project_root)/bin/drush $(drush_alias) sqlsan -y
	# Set admin user password to "drupaladm1n".
	@echo "Admin password is set to 'drupaladm1n'"
	@docker-compose exec -T php $(project_root)/bin/drush $(drush_alias) upwd admin "drupaladm1n"

profile-setup: #hidden target to consolidate steps needed in devinit and prodinit
	## The following is done because nginx spawns child processes that are not running as root, and are blocked from writing to the files directory due to file permissions issues
	#@make import-db
	@make initialize-db
	#@make import-files
	@docker-compose exec $(PROJECT_NAME).test /bin/bash -c "chmod -Rf a+w $(project_root)/docroot/sites/default/files"
	@make cache-reset

initialize-db:
	## used when initializing a project, shoudl be replaced with make import-db when a seed db is available to import
	@docker-compose exec php $(project_root)/bin/drush $(drush_alias) si standard --db-url=mysql://drupal:drupal@db/drupal --account-name=admin --account-pass=drupaladm1n --site-name=$(SITE_NAME) -y
	@docker-compose exec php $(project_root)/bin/drush $(drush_alias) config-set "system.site" uuid "$(uuid)" -y
	@docker-compose exec php $(project_root)/bin/drush $(drush_alias) ev '\Drupal::entityManager()->getStorage("shortcut_set")->load("default")->delete();'
	@docker-compose exec php $(project_root)/bin/drush $(drush_alias) ev '\Drupal::entityManager()->getStorage("node_type")->load("article")->delete();'
	@docker-compose exec php $(project_root)/bin/drush $(drush_alias) pm-uninstall shortcut -y

scan-custom-deprecated:
	@docker-compose exec php $(project_root)/bin/drupal-check docroot/modules/custom
	@docker-compose exec php $(project_root)/bin/drupal-check docroot/themes/custom
	@docker-compose exec php $(project_root)/bin/drupal-check docroot/profiles/custom

# https://stackoverflow.com/a/6273809/1826109
%: ## result when make target does not exist
	@:
