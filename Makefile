# SOURCE: https://github.com/autopilotpattern/jenkins/blob/master/makefile
MAKEFLAGS += --warn-undefined-variables
# .SHELLFLAGS := -eu -o pipefail

DNSMASQ_DOMAIN         := hyenaclan.org
# URL_PATH_MONGO_EXPRESS := 8081
# URL_PATH_FLASK_APP     := 8888
# URL_PATH_UWSGI_STATS   := 9191
# URL_PATH_LOCUST_MASTER := 8089
# URL_PATH_CONSUL        := 8500
# URL_PATH_TRAEFIK       := 80
# URL_PATH_TRAEFIK_API   := 8080
URL_PATH_ARA              := "http://127.0.0.1:9191"
URL_PATH_NETDATA_MASTER1  := "http://borg-queen-01.scarlettlab.home:19999"
URL_PATH_NETDATA_WORKER1  := "http://borg-worker-01.scarlettlab.home:19999"
URL_PATH_NETDATA_WORKER2  := "http://borg-worker-02.scarlettlab.home:19999"

URL_PATH_NETDATA_REGISTRY  := "http://rsyslogd-master-01.$(DNSMASQ_DOMAIN):19999"
URL_PATH_NETDATA_NODE      := "http://rsyslogd-worker-01.$(DNSMASQ_DOMAIN):19999"
URL_PATH_WHOAMI            := "http://whoami.$(DNSMASQ_DOMAIN)"
URL_PATH_ECHOSERVER        := "http://echoserver.$(DNSMASQ_DOMAIN)"
URL_PATH_ELASTICSEARCH     := "http://elasticsearch.$(DNSMASQ_DOMAIN)"
URL_PATH_ELASTICSEARCH_HEAD     := "http://elasticsearch-head.$(DNSMASQ_DOMAIN)"
URL_PATH_ELASTICSEARCH_HQ     := "http://elasticsearch-hq.$(DNSMASQ_DOMAIN)"
URL_PATH_KIBANA            := "http://kibana.$(DNSMASQ_DOMAIN)"
URL_PATH_PROMETHEUS        := "http://prometheus.$(DNSMASQ_DOMAIN)"
URL_PATH_GRAFANA           := "http://grafana.$(DNSMASQ_DOMAIN)"
URL_PATH_ALERTMANAGER      := "http://alertmanager.$(DNSMASQ_DOMAIN)"
URL_PATH_DASHBOARD         := "http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/"

# rsync -avz --dry-run --exclude 'README.md' --exclude '*.log' --exclude '.git' --exclude '.vscode' --exclude '.vagrant' --exclude '.gitignore' --exclude '.retry' ~/dev/bossjones/boss-ansible-homelab/.[^.]* ~/dev/bossjones/bosslab-playbooks
# rsync -avz --dry-run --exclude 'README.md' --exclude '*.log' --exclude '.git' --exclude '.vscode' --exclude '.vagrant'  ~/dev/bossjones/boss-ansible-homelab/{inventory-vagrant,inventory-homelab,decrypt_all.sh,encrypt_all.sh,vars,git_hooks,vault_password,group_vars} ~/dev/bossjones/bosslab-playbooks

# SOURCE: https://github.com/wk8838299/bullcoin/blob/8182e2f19c1f93c9578a2b66de6a9cce0506d1a7/LMN/src/makefile.osx
HAVE_BREW=$(shell brew --prefix >/dev/null 2>&1; echo $$? )

.PHONY: list help default all check fail-when-git-dirty

.PHONY: FORCE_MAKE

PR_SHA                := $(shell git rev-parse HEAD)

define ASCILOGO
kubernetes-cluster-vagrant
=======================================
endef

export ASCILOGO

# http://misc.flogisoft.com/bash/tip_colors_and_formatting

RED=\033[0;31m
GREEN=\033[0;32m
ORNG=\033[38;5;214m
BLUE=\033[38;5;81m
NC=\033[0m

export RED
export GREEN
export NC
export ORNG
export BLUE

# verify that certain variables have been defined off the bat
check_defined = \
    $(foreach 1,$1,$(__check_defined))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $(value 2), ($(strip $2)))))


export PATH := ./venv/bin:$(PATH)

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))
MAKE := make

list_allowed_args := product ip command role tier

ifeq (${OS}, Windows_NT)
    DETECTED_OS := Windows
else
    DETECTED_OS := $(shell uname -s)
endif

default: all

all: galaxy

check: all fail-when-git-dirty

fail-when-git-dirty:
	git diff --quiet && git diff --cached --quiet

galaxy: galaxy/requirements
	@echo 'You need to `git add` all files in order for this script to pick up the changes!'

galaxy/requirements: galaxy/requirements.yml

galaxy/requirements.yml: scripts/get_all_referenced_roles FORCE_MAKE
ifeq (${DETECTED_OS}, Darwin)
	"$<" | gsed --regexp-extended 's/^(.*)$$/- src: \1\n/' > "$@"
else
	"$<" | sed --regexp-extended 's/^(.*)$$/- src: \1\n/' > "$@"
endif

list:
	@$(MAKE) -qp | awk -F':' '/^[a-zA-Z0-9][^$#\/\t=]*:([^=]|$$)/ {split($$1,A,/ /);for(i in A)print A[i]}' | sort

download-roles:
	ansible-galaxy install -r galaxy/requirements.yml --roles-path ./roles/

download-roles-force:
	ansible-galaxy --force install -r galaxy/requirements.yml --roles-path ./roles/

download-roles-global:
	ansible-galaxy install -r galaxy/requirements.yml --roles-path=/etc/ansible/roles

download-roles-global-force:
	ansible-galaxy install --force -r galaxy/requirements.yml --roles-path=/etc/ansible/roles

raw:
	$(call check_defined, product, Please set product)
	$(call check_defined, command, Please set command)
	@ansible localhost -i inventory-$(product)/ ${PROXY_COMMAND} -m raw -a "$(command)" -f 10

# Compile python modules against homebrew openssl. The homebrew version provides a modern alternative to the one that comes packaged with OS X by default.
# OS X's older openssl version will fail against certain python modules, namely "cryptography"
# Taken from this git issue pyca/cryptography#2692
install-virtualenv-osx:
	ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/opt/openssl/lib" CFLAGS="-I/usr/local/opt/openssl/include" pip install -r requirements.txt

install-cidr-brew:
	pip install cidr-brewer

install-test-deps-pre:
	pip install docker-py
	pip install molecule --pre

install-test-deps:
	pip install docker-py
	pip install molecule

pre_commit_install:
	cp git_hooks/pre-commit .git/hooks/pre-commit

travis:
	tox

.PHONY: pip-tools
pip-tools:
ifeq (${DETECTED_OS}, Darwin)
	ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/opt/openssl/lib" CFLAGS="-I/usr/local/opt/openssl/include" pip install pip-tools pipdeptree
else
	pip install pip-tools pipdeptree
endif

.PHONY: pip-tools-osx
.PHONY: pip-tools-osx
pip-tools-osx: pip-tools

.PHONY: pip-compile-upgrade-all
pip-compile-upgrade-all: pip-tools
	pip-compile --output-file requirements.txt requirements.in --upgrade
	pip-compile --output-file requirements-dev.txt requirements-dev.in --upgrade
	pip-compile --output-file requirements-test.txt requirements-test.in --upgrade

.PHONY: pip-compile
pip-compile: pip-tools
	pip-compile --output-file requirements.txt requirements.in
	pip-compile --output-file requirements-dev.txt requirements-dev.in
	pip-compile --output-file requirements-test.txt requirements-test.in

.PHONY: install-deps-all
install-deps-all:
	pip install -r requirements.txt
	pip install -r requirements-dev.txt

provision:
	@bash ./scripts/up.sh
	vagrant sandbox commit
	vagrant reload
	time ansible-playbook -i inventory.ini vagrant_playbook.yml -v

up:
	@bash ./scripts/up.sh

rollback:
	@bash ./scripts/rollback.sh

commit:
	vagrant sandbox commit

reload:
	@vagrant reload

destroy:
	@vagrant halt -f
	@vagrant destroy -f

run-ansible:
	@time ansible-playbook -i inventory.ini playbooks/vagrant_playbook.yml -v

.ansible-logs:
	mkdir .ansible-logs

run-ansible-sysdig-profiler: .ansible-logs
	@time ansible-playbook -i inventory.ini playbooks/sysdig_profile.yml --extra-vars "num_seconds=20" -f 10 -v
	tree playbooks/.ansible-logs/

run-ansible-sysdig-profiler-10s:
	@time ansible-playbook -i inventory.ini playbooks/sysdig_profile.yml --extra-vars "num_seconds=10" -f 10 -v
	tree playbooks/.ansible-logs/
# tar xvf debug.tar.gz --strip 2

run-ansible-nfs:
	@time ansible-playbook -i inventory.ini playbooks/vagrant_nfs.yml -v

run-ansible-influxdb:
	@time ansible-playbook -i inventory.ini playbooks/vagrant_influxdb_opentsdb.yml -v

run-ansible-list-tags:
	@time ansible-playbook -i inventory.ini playbooks/vagrant_playbook.yml -v --list-tasks

run-ansible-rsyslogd:
	@time ansible-playbook -i inventory.ini rsyslogd_playbook.yml -v

run-ansible-etckeeper:
	@time ansible-playbook -i inventory.ini vagrant_playbook.yml -v -f 10 --tags etckeeper

run-ansible-rvm:
	@time ansible-playbook -i inventory.ini vagrant_playbook.yml -v -f 10 --tags 'ruby'

run-ansible-ruby: run-ansible-rvm

# For performance tuning/measuring
run-ansible-netdata:
	@time ansible-playbook -i inventory.ini playbooks/vagrant_netdata.yml -v

# For performance tuning/measuring
run-ansible-tuning:
	@time ansible-playbook -i inventory.ini tuning.yml -v

run-ansible-perf: run-ansible-tuning

run-ansible-tools:
	@time ansible-playbook -i inventory.ini playbooks/vagrant_tools.yml -f 10 -v

run-ansible-repos:
	@time ansible-playbook -i inventory.ini playbooks/vagrant_repos.yml -f 10 -v

run-ansible-modprobe:
	@time ansible-playbook -i inventory.ini playbooks/vagrant_modprode.yml -f 10 -v

run-ansible-goss:
	@time ansible-playbook -i inventory.ini tools.yml -v -f 10 --tags goss

run-ansible-docker:
	@time ansible-playbook -i inventory.ini playbooks/vagrant_playbook.yml -v --tags docker-provision --flush-cache

run-ansible-master:
	@time ansible-playbook -i inventory.ini vagrant_playbook.yml -v --tags primary_master

run-ansible-timezone:
	@time ansible-playbook -i inventory.ini timezone.yml -v

converge: up run-ansible-modprobe run-ansible run-ansible-tools

ping:
	@time ansible-playbook -v -i inventory.ini ping.yml -v

ansible-run-dynamic-debug:
	@time ansible-playbook -v -i inventory.ini dynamic_vars.yml

# [ANSIBLE0013] Use shell only when shell functionality is required
ansible-lint-role:
	bash -c "find .* -type f -name '*.y*ml' ! -name '*.venv' -print0 | xargs -I FILE -t -0 -n1 ansible-lint -x ANSIBLE0006,ANSIBLE0007,ANSIBLE0010,ANSIBLE0013 FILE"

yamllint-role:
	bash -c "find .* -type f -name '*.y*ml' ! -name '*.venv' -print0 | xargs -I FILE -t -0 -n1 yamllint FILE"

install-ip-cmd-osx:
	brew install iproute2mac

flush-cache:
	@sudo killall -HUP mDNSResponder

bridge-up:
	./vagrant_bridged_demo.sh --full --bridged_adapter auto

bridge-restart:
	./vagrant_bridged_demo.sh --restart

bridge-start:
	./vagrant_bridged_demo.sh --start

bridge-halt:
	vagrant halt

ssh-bridge-master:
	ssh -vvvv -F ./ssh_config rsyslogd-master-01.scarlettlab.home

ssh-bridge-worker:
	ssh -vvvv -F ./ssh_config rsyslogd-worker-01.scarlettlab.home

ping-bridge:
	@time ansible-playbook -v -i hosts ping.yml

run-bridge-ansible:
	@time ansible-playbook -i hosts vagrant_playbook.yml -v

run-bridge-test-ansible:
	@time ansible-playbook -i hosts test.yml -v

run-bridge-tools-ansible:
	@time ansible-playbook -i hosts tools.yml -v

run-bridge-ping-ansible:
	@time ansible-playbook -i hosts ping.yml -v

run-bridge-log-iptables-ansible:
	@time ansible-playbook -i hosts log_iptables.yml -v

run-bridge-ansible-no-slow:
	@time ansible-playbook -i hosts vagrant_playbook.yml -v --skip-tags "slow"

run-bridge-debug-ansible:
	@time ansible-playbook -i hosts debug.yml -v

dummy-web-server:
	python dummy-web-server.py

rebuild: destroy flush-cache bridge-up sleep ping-bridge run-bridge-ansible run-bridge-tools-ansible

# pip install graphviz
graph-inventory:
	ansible-inventory-grapher -i inventory.ini -d static/graphs/bosslab --format "bosslab-{hostname}.dot" -a "rankdir=LR; splines=ortho; ranksep=2; node [ width=5 style=filled fillcolor=lightgrey ]; edge [ dir=back arrowtail=empty ];" borg-queen-01.scarlettlab.home
# for f in static/graphs/bosslab/*.dot ; do dot -Tpng -o static/graphs/bosslab/`basename $f .dot`.png $f; done

graph-inventory-view:
	ansible-inventory-grapher -i inventory.ini -d static/graphs/bosslab --format "bosslab-{hostname}.dot" -a "rankdir=LR; splines=ortho; ranksep=2; node [ width=5 style=filled fillcolor=lightgrey ]; edge [ dir=back arrowtail=empty ];" borg-queen-01.scarlettlab.home |prod-web-server-1a | dot -Tpng | display png:-

# nvm-install:
# 	nvm install stable ;
# 	nvm use stable ;
# 	npm install npm@latest -g ;
# 	npm install -g docker-loghose ;
# 	npm install -g docker-enter ;

# hostnames-pod:
# 	kubectl run hostnames --image=k8s.gcr.io/serve_hostname \
# 	--labels=app=hostnames \
#     --port=9376 \
#     --replicas=3 ; \
# 	kubectl get pods -l app=hostnames ; \
# 	kubectl expose deployment hostnames --port=80 --target-port=9376 ; \

pip-install-pygments:
	pip install Pygments

multi-ssh-homelab:
	i2cssh -XF=~/dev/bossjones/kubernetes-cluster/ssh_config.borg -Xi=~/.ssh/vagrant_id_rsa borg-homelab

multi-ssh-vagrant:
	i2cssh -XF=~/dev/bossjones/kubernetes-cluster/ssh_config -Xi=~/.ssh/vagrant_id_rsa vagrant-kube

i2cssh-vagrant: multi-ssh-vagrant

i2cssh-borg: multi-ssh-homelab

borg-ssh: multi-ssh-homelab

# open-netdata-registry:
# 	./scripts/open-browser.py $(URL_PATH_NETDATA_REGISTRY)

# open-netdata-node:
# 	./scripts/open-browser.py $(URL_PATH_NETDATA_NODE)

open-ara:
	./scripts/open-browser.py $(URL_PATH_ARA)

open-netdata-vagrant:
	./scripts/open-browser.py $(URL_PATH_NETDATA_MASTER1)
	./scripts/open-browser.py $(URL_PATH_NETDATA_WORKER1)
	./scripts/open-browser.py $(URL_PATH_NETDATA_WORKER2)

open-netdata: open-netdata-vagrant

# open: open-netdata

open-vagrant: open-netdata-vagrant

# # https://docs.debops.org/en/latest/ansible/roles/debops.core/getting-started.html
# # To see what facts are configured on a host, run command:
# ansible <hostname> -s -m setup -a 'filter=ansible_local'
# The list of Ansible Controller IP addresses is accessible as ansible_local.core.ansible_controllers for other roles to use as needed.
# https://github.com/debops/debops-playbooks

get-local-facts:
	@echo "To see what facts are configured on a host"
	ansible servers -i inventory.ini -s -m setup -a 'filter=ansible_local'


###########################################################
# Pyenv initilization - 12/23/2018 -- START
# SOURCE: https://github.com/MacHu-GWU/learn_datasette-project/blob/120b45363aa63bdffe2f1933cf2d4e20bb6cbdb8/make/python_env.mk
###########################################################

#--- User Defined Variable ---
PACKAGE_NAME="bosslab-playbooks"

# Python version Used for Development
PY_VER_MAJOR="2"
PY_VER_MINOR="7"
PY_VER_MICRO="14"

#  Other Python Version You Want to Test With
# (Only useful when you use tox locally)
# TEST_PY_VER3="3.4.6"
# TEST_PY_VER4="3.5.3"
# TEST_PY_VER5="3.6.2"

# If you use pyenv-virtualenv, set to "Y"
USE_PYENV="Y"

#--- Derive Other Variable ---

# Virtualenv Name
VENV_NAME="${PACKAGE_NAME}${PY_VER_MAJOR}"

# Project Root Directory
GIT_ROOT_DIR=${shell git rev-parse --show-toplevel}
PROJECT_ROOT_DIR=${shell pwd}

ifeq (${OS}, Windows_NT)
    DETECTED_OS := Windows
else
    DETECTED_OS := $(shell uname -s)
endif


# ---------

# Windows
ifeq (${DETECTED_OS}, Windows)
    USE_PYENV="N"

    VENV_DIR_REAL="${PROJECT_ROOT_DIR}/${VENV_NAME}"
    BIN_DIR="${VENV_DIR_REAL}/Scripts"
    SITE_PACKAGES="${VENV_DIR_REAL}/Lib/site-packages"
    SITE_PACKAGES64="${VENV_DIR_REAL}/Lib64/site-packages"

    GLOBAL_PYTHON="/c/Python${PY_VER_MAJOR}${PY_VER_MINOR}/python.exe"
    OPEN_COMMAND="start"
endif


# MacOS
ifeq (${DETECTED_OS}, Darwin)

ifeq ($(USE_PYENV), "Y")
    ARCHFLAGS="-arch x86_64"
    LDFLAGS="-L/usr/local/opt/openssl/lib"
    CFLAGS="-I/usr/local/opt/openssl/include"
    VENV_DIR_REAL="${HOME}/.pyenv/versions/${PY_VERSION}/envs/${VENV_NAME}"
    VENV_DIR_LINK="${HOME}/.pyenv/versions/${VENV_NAME}"
    BIN_DIR="${VENV_DIR_REAL}/bin"
    SITE_PACKAGES="${VENV_DIR_REAL}/lib/python${PY_VER_MAJOR}.${PY_VER_MINOR}/site-packages"
    SITE_PACKAGES64="${VENV_DIR_REAL}/lib64/python${PY_VER_MAJOR}.${PY_VER_MINOR}/site-packages"
else
    ARCHFLAGS="-arch x86_64"
    LDFLAGS="-L/usr/local/opt/openssl/lib"
    CFLAGS="-I/usr/local/opt/openssl/include"
    VENV_DIR_REAL="${PROJECT_ROOT_DIR}/${VENV_NAME}"
    VENV_DIR_LINK="./${VENV_NAME}"
    BIN_DIR="${VENV_DIR_REAL}/bin"
    SITE_PACKAGES="${VENV_DIR_REAL}/lib/python${PY_VER_MAJOR}.${PY_VER_MINOR}/site-packages"
    SITE_PACKAGES64="${VENV_DIR_REAL}/lib64/python${PY_VER_MAJOR}.${PY_VER_MINOR}/site-packages"
endif
    ARCHFLAGS="-arch x86_64"
    LDFLAGS="-L/usr/local/opt/openssl/lib"
    CFLAGS="-I/usr/local/opt/openssl/include"

    GLOBAL_PYTHON="python${PY_VER_MAJOR}.${PY_VER_MINOR}"
    OPEN_COMMAND="open"
endif


# Linux
ifeq (${DETECTED_OS}, Linux)
    USE_PYENV="N"

    VENV_DIR_REAL="${PROJECT_ROOT_DIR}/${VENV_NAME}"
    VENV_DIR_LINK="${PROJECT_ROOT_DIR}/${VENV_NAME}"
    BIN_DIR="${VENV_DIR_REAL}/bin"
    SITE_PACKAGES="${VENV_DIR_REAL}/lib/python${PY_VER_MAJOR}.${PY_VER_MINOR}/site-packages"
    SITE_PACKAGES64="${VENV_DIR_REAL}/lib64/python${PY_VER_MAJOR}.${PY_VER_MINOR}/site-packages"

    GLOBAL_PYTHON="python${PY_VER_MAJOR}.${PY_VER_MINOR}"
    OPEN_COMMAND="open"
endif


BASH_PROFILE_FILE = "${HOME}/.bash_profile"

BIN_ACTIVATE="${BIN_DIR}/activate"
BIN_PYTHON="${BIN_DIR}/python"
BIN_PIP="${BIN_DIR}/pip"
BIN_ISORT="${BIN_DIR}/isort"
BIN_JINJA="${BIN_DIR}/jinja2"

PY_VERSION="${PY_VER_MAJOR}.${PY_VER_MINOR}.${PY_VER_MICRO}"

.PHONY: help
help: ## ** Show this help message
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

#--- Make Commands ---
.PHONY: info
info: ## ** Show information about python, pip in this environment
	@printf "Info:\n"
	@printf "=======================================\n"
	@printf "$$GREEN venv:$$NC                               ${VENV_DIR_REAL}\n"
	@printf "$$GREEN python executable:$$NC                  ${BIN_PYTHON}\n"
	@printf "$$GREEN pip executable:$$NC                     ${BIN_PIP}\n"
	@printf "$$GREEN site-packages:$$NC                      ${SITE_PACKAGES}\n"
	@printf "$$GREEN site-packages64:$$NC                    ${SITE_PACKAGES64}\n"
	@printf "$$GREEN venv-dir-real:$$NC                      ${VENV_DIR_REAL}\n"
	@printf "$$GREEN venv-dir-link:$$NC                      ${VENV_DIR_LINK}\n"
	@printf "$$GREEN venv-bin-dir:$$NC                       ${BIN_DIR}\n"
	@printf "$$GREEN bash-profile-file:$$NC                  ${BASH_PROFILE_FILE}\n"
	@printf "$$GREEN bash-activate:$$NC                      ${BIN_ACTIVATE}\n"
	@printf "$$GREEN bin-python:$$NC                         ${BIN_PYTHON}\n"
	@printf "$$GREEN bin-isort:$$NC                          ${BIN_ISORT}\n"
	@printf "$$GREEN py-version:$$NC                         ${PY_VERSION}\n"
	@printf "$$GREEN use-pyenv:$$NC                          ${USE_PYENV}\n"
	@printf "$$GREEN venv-name:$$NC                          ${VENV_NAME}\n"
	@printf "$$GREEN git-root-dir:$$NC                       ${GIT_ROOT_DIR}\n"
	@printf "$$GREEN project-root-dir:$$NC                   ${PROJECT_ROOT_DIR}\n"
	@printf "$$GREEN brew-is-installed:$$NC                  ${HAVE_BREW}\n"
	@printf "\n"

#--- Virtualenv ---
.PHONY: brew_install_pyenv
brew_install_pyenv: ## ** Install pyenv and pyenv-virtualenv
	-brew install pyenv
	-brew install pyenv-virtualenv

.PHONY: setup_pyenv
setup_pyenv: brew_install_pyenv enable_pyenv ## ** Do some pre-setup for pyenv and pyenv-virtualenv
	pyenv install ${PY_VERSION} -s
	pyenv rehash

.PHONY: bootstrap_venv
bootstrap_venv: pre_commit_install init_venv dev_dep show_venv_activate_cmd ## ** Create virtual environment, initialize it, install packages, and remind user to activate after make is done
# bootstrap_venv: init_venv dev_dep ## ** Create virtual environment, initialize it, install packages, and remind user to activate after make is done

.PHONY: init_venv
init_venv: ## ** Initiate Virtual Environment
ifeq (${USE_PYENV}, "Y")
	# Install pyenv
	#-brew install pyenv
	#-brew install pyenv-virtualenv

	# # Edit Config File
	# if ! grep -q 'export PYENV_ROOT="$$HOME/.pyenv"' "${BASH_PROFILE_FILE}" ; then\
	#     echo 'export PYENV_ROOT="$$HOME/.pyenv"' >> "${BASH_PROFILE_FILE}" ;\
	# fi
	# if ! grep -q 'export PATH="$$PYENV_ROOT/bin:$$PATH"' "${BASH_PROFILE_FILE}" ; then\
	#     echo 'export PATH="$$PYENV_ROOT/bin:$$PATH"' >> "${BASH_PROFILE_FILE}" ;\
	# fi
	# if ! grep -q 'eval "$$(pyenv init -)"' "${BASH_PROFILE_FILE}" ; then\
	#     echo 'eval "$$(pyenv init -)"' >> "${BASH_PROFILE_FILE}" ;\
	# fi
	# if ! grep -q 'eval "$$(pyenv virtualenv-init -)"' "${BASH_PROFILE_FILE}" ; then\
	#     echo 'eval "$$(pyenv virtualenv-init -)"' >> "${BASH_PROFILE_FILE}" ;\
	# fi

	# pyenv install ${PY_VERSION} -s
	# pyenv rehash

	-pyenv virtualenv ${PY_VERSION} ${VENV_NAME}
	@printf "FINISHED:\n"
	@printf "=======================================\n"
	@printf "$$GREEN Run to activate virtualenv:$$NC                               pyenv activate ${VENV_NAME}\n"
else

ifeq ($(HAVE_BREW), 0)
	DEPSDIR='ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/opt/openssl/lib" CFLAGS="-I/usr/local/opt/openssl/include"'
	$(DEPSDIR) virtualenv -p ${GLOBAL_PYTHON} ${VENV_NAME}
endif

	virtualenv -p ${GLOBAL_PYTHON} ${VENV_NAME}
endif


.PHONY: up
up: init_venv ## ** Set Up the Virtual Environment


.PHONY: clean_venv
clean_venv: ## ** Clean Up Virtual Environment
ifeq (${USE_PYENV}, "Y")
	-pyenv uninstall -f ${VENV_NAME}
else
	test -r ${VENV_DIR_REAL} || echo "DIR exists: ${VENV_DIR_REAL}" || rm -rv ${VENV_DIR_REAL}
endif


#--- Install ---

.PHONY: uninstall
uninstall: ## ** Uninstall This Package
	# -${BIN_PIP} uninstall -y ${PACKAGE_NAME}
	-${BIN_PIP} uninstall -y requirements.txt

.PHONY: install
# install: uninstall ## ** Install This Package via setup.py
install: ## ** Install This Package via setup.py
ifeq ($(HAVE_BREW), 0)
	DEPSDIR='ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/opt/openssl/lib" CFLAGS="-I/usr/local/opt/openssl/include"'
	$(DEPSDIR) ${BIN_PIP} install -r requirements.txt
else
	${BIN_PIP} install -r requirements.txt
endif


.PHONY: dev_dep
dev_dep: ## ** Install Development Dependencies

ifeq ($(HAVE_BREW), 0)
	( \
		cd ${PROJECT_ROOT_DIR}; \
		ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/opt/openssl/lib" CFLAGS="-I/usr/local/opt/openssl/include" ${BIN_PIP} install -r requirements.txt; \
	)
else
	( \
		cd ${PROJECT_ROOT_DIR}; \
		${BIN_PIP} install -r requirements.txt; \
	)
endif


.PHONY: show_venv_activate_cmd
show_venv_activate_cmd: ## ** Show activate command when finished
	@printf "Don't forget to run this activate your new virtualenv:\n"
	@printf "=======================================\n"
	@echo
	@printf "$$GREEN pyenv activate $(VENV_NAME)$$NC\n"
	@echo
	@printf "=======================================\n"

# Frequently used make command:
#
# - make up
# - make clean
# - make install
# - make test
# - make tox
# - make build_doc
# - make view_doc
# - make deploy_doc
# - make reformat
# - make publish

###########################################################
# Pyenv initilization - 12/23/2018 -- END
# SOURCE: https://github.com/MacHu-GWU/learn_datasette-project/blob/120b45363aa63bdffe2f1933cf2d4e20bb6cbdb8/make/python_env.mk
###########################################################

dump-color:
	kubectl cluster-info dump --all-namespaces | highlight

dump-to-dir:
	kubectl cluster-info dump --all-namespaces --output-directory=./dump

dump2-to-dir:
	kubectl cluster-info dump --all-namespaces --output-directory=./dump2

# https://github.com/kubernetes/dashboard/wiki/Access-control#bearer-token
get-secrets:
	kubectl -n kube-system get secret

# addon-dashboard:
# 	kubectl apply -f ./addon/dashboard/kubernetes-dashboard.yaml

list-services:
	kubectl get ingress,services -n=kube-system

list-ingress:
	@kubectl get ingress -n=kube-system -o yaml | highlight

start-ara:
	@bash ./scripts/start-ara.sh

get-token:
	@bash ./scripts/get-root-token.sh

kube-proxy:
	@bash ./scripts/kubectl-proxy.sh

kubectl-proxy: kube-proxy

get-token-copy:
	@bash ./scripts/get-root-token.sh | pbcopy

get-bearer-token: get-token

# SOURCE: https://github.com/coreos/prometheus-operator/tree/7f34279e7c69124a80248cc54cadef93fd1b2387/contrib/kube-prometheus
addon-prometheus-operator:
	@printf "addon-prometheus-operator:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy prometheus-operator$$NC\n"
	@printf "=======================================\n"
	-kubectl create -f ./prometheus-operator/ || true
	@echo
	@echo "It can take a few seconds for the above 'create manifests' command to fully create the following resources, so verify the resources are ready before proceeding."
	until kubectl get customresourcedefinitions servicemonitors.monitoring.coreos.com ; do date; sleep 1; echo ""; done
	@echo
	until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
	@echo

create-prometheus-operator: addon-prometheus-operator

apply-prometheus-operator:
	@printf "create-prometheus-operator:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy prometheus-operator$$NC\n"
	@printf "=======================================\n"
	kubectl apply -f ./prometheus-operator/
	@echo ""
	@echo ""
# kubectl get pods --all-namespaces -l app=prometheus-operator --watch

delete-prometheus-operator:
	kubectl delete -f ./prometheus-operator/

describe-prometheus-operator:
	kubectl describe -f ./prometheus-operator/ | highlight

debug-prometheus-operator: describe-prometheus-operator
	kubectl -n kube-system get pod -l app=prometheus-operator --output=yaml | highlight


###########################################################################################################################################
###########################################################################################################################################
###########################################################################################################################################

# FYI I built all of this using jsonnet and all of that jazz 1/12/2019
# SOURCE: https://github.com/coreos/prometheus-operator/tree/master/contrib/kube-prometheus
addon-prometheus-operator-v0-27-0:
	@printf "addon-prometheus-operator-v0-27-0:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy prometheus-operator-v0-27-0$$NC\n"
	@printf "=======================================\n"
	-kubectl create -f ./prometheus-operator-v0-27-0/ || true
	@echo
	@echo "It can take a few seconds for the above 'create manifests' command to fully create the following resources, so verify the resources are ready before proceeding."
	until kubectl get customresourcedefinitions servicemonitors.monitoring.coreos.com ; do date; sleep 1; echo ""; done
	@echo
	until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
	@echo

create-prometheus-operator-v0-27-0: addon-prometheus-operator-v0-27-0

apply-prometheus-operator-v0-27-0:
	@printf "create-prometheus-operator-v0-27-0:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy prometheus-operator-v0-27-0$$NC\n"
	@printf "=======================================\n"
	kubectl apply -f ./prometheus-operator-v0-27-0/
	@echo ""
	@echo ""
# kubectl get pods --all-namespaces -l app=prometheus-operator-v0-27-0 --watch

delete-prometheus-operator-v0-27-0:
	kubectl delete -f ./prometheus-operator-v0-27-0/

describe-prometheus-operator-v0-27-0:
	kubectl describe -f ./prometheus-operator-v0-27-0/ | highlight

debug-prometheus-operator-v0-27-0: describe-prometheus-operator-v0-27-0
	kubectl -n kube-system get pod -l app=prometheus-operator-v0-27-0 --output=yaml | highlight


open-dashboard:
	./scripts/open-browser.py $(URL_PATH_DASHBOARD)

open-whoami:
	./scripts/open-browser.py $(URL_PATH_WHOAMI)

open-echoserver:
	./scripts/open-browser.py $(URL_PATH_ECHOSERVER)

open-elasticsearch:
	./scripts/open-browser.py $(URL_PATH_ELASTICSEARCH)

open-elasticsearch-hq:
	./scripts/open-browser.py $(URL_PATH_ELASTICSEARCH_HQ)

open-elasticsearch-head:
	./scripts/open-browser.py $(URL_PATH_ELASTICSEARCH_HEAD)

open-kibana:
	./scripts/open-browser.py $(URL_PATH_KIBANA)

open-prometheus:
	./scripts/open-browser.py $(URL_PATH_PROMETHEUS)

open-grafana:
	./scripts/open-browser.py $(URL_PATH_GRAFANA)

open-alertmanager:
	./scripts/open-browser.py $(URL_PATH_ALERTMANAGER)

# open: open-mongo-express open-flask-app open-uwsgi-stats open-locust-master open-consul open-traefik open-traefik-api open-whoami
open: open-whoami open-dashboard open-echoserver open-elasticsearch open-kibana open-prometheus open-grafana open-alertmanager open-netdata

create-heapster:
	@printf "create-heapster:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy heapster$$NC\n"
	@printf "=======================================\n"
	kubectl create -f ./heapster2/
	@echo ""
	@echo ""
# kubectl get pods --all-namespaces -l app=heapster --watch | highlight

apply-heapster:
	@printf "create-heapster:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy heapster$$NC\n"
	@printf "=======================================\n"
	kubectl apply -f ./heapster2/
	@echo ""
	@echo ""
# kubectl get pods --all-namespaces -l app=heapster --watch

delete-heapster:
	kubectl delete -f ./heapster2/

describe-heapster:
	kubectl describe -f ./heapster2/ | highlight

debug-heapster: describe-heapster
	kubectl -n kube-system get pod -l app=heapster --output=yaml | highlight

create-dashboard:
	@printf "create-dashboard:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy kubernetes dashboard$$NC\n"
	@printf "$$GREEN create admin role token$$NC\n"
	@printf "=======================================\n"
	kubectl create -f ./dashboard/
	@printf "=======================================\n"
	@printf "$$GREEN the admin role token is:$$NC\n"
	@printf "=======================================\n"
	@echo ""
	@echo $(shell kubectl -n kube-system describe secret `kubectl -n kube-system get secret|grep admin-token|cut -d " " -f1`|grep "token:"|tr -s " "|cut -d " " -f2)

apply-dashboard:
	@printf "create-dashboard:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy kubernetes dashboard$$NC\n"
	@printf "$$GREEN create admin role token$$NC\n"
	@printf "=======================================\n"
	kubectl apply -f ./dashboard/
	@printf "=======================================\n"
	@printf "$$GREEN the admin role token is:$$NC\n"
	@printf "=======================================\n"
	@echo ""
	@echo $(shell kubectl -n kube-system describe secret `kubectl -n kube-system get secret|grep admin-token|cut -d " " -f1`|grep "token:"|tr -s " "|cut -d " " -f2)

describe-dashboard:
	kubectl describe -f ./dashboard/ | highlight

debug-dashboard:
	kubectl -n kube-system get pod -l k8s-app=kubernetes-dashboard --output=yaml | highlight

# kubernetes-dashboard

delete-dashboard:
	kubectl delete -f ./dashboard/

create-dashboard-admin:
	@printf "create-dashboard-admin:\n"
	@printf "=======================================\n"
	@printf "$$GREEN create cluster-admin role $$NC\n"
	@printf "=======================================\n"
	kubectl create -f ./dashboard-admin/

apply-dashboard-admin:
	@printf "apply-dashboard-admin:\n"
	@printf "=======================================\n"
	@printf "$$GREEN apply cluster-admin role $$NC\n"
	@printf "=======================================\n"
	kubectl apply -f ./dashboard-admin/

delete-dashboard-admin:
	kubectl delete -f ./dashboard-admin/

create-ingress-nginx:
	@printf "create-ingress-nginx:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy ingress-nginx$$NC\n"
	@printf "=======================================\n"
	kubectl create -f ./ingress-nginx/
	@echo ""
	@echo ""
# kubectl get pods --all-namespaces -l app=ingress-nginx --watch | highlight

apply-ingress-nginx:
	@printf "create-ingress-nginx:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy ingress-nginx$$NC\n"
	@printf "=======================================\n"
	kubectl apply -f ./ingress-nginx/
	@echo ""
	@echo ""
# kubectl get pods --all-namespaces -l app=ingress-nginx --watch

delete-ingress-nginx:
	kubectl delete -f ./ingress-nginx/

describe-ingress-nginx:
	kubectl describe -f ./ingress-nginx/ | highlight

debug-ingress-nginx: describe-ingress-nginx
	kubectl -n kube-system get pod -l app=ingress-nginx --output=yaml | highlight


create-echoserver:
	@printf "create-echoserver:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy echoserver$$NC\n"
	@printf "=======================================\n"
	kubectl create -f ./echoserver/
	@echo ""
	@echo ""
# kubectl get pods --all-namespaces -l app=echoserver --watch | highlight

apply-echoserver:
	@printf "create-echoserver:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy echoserver$$NC\n"
	@printf "=======================================\n"
	kubectl apply -f ./echoserver/
	@echo ""
	@echo ""
# kubectl get pods --all-namespaces -l app=echoserver --watch

delete-echoserver:
	kubectl delete -f ./echoserver/

describe-echoserver:
	kubectl describe -f ./echoserver/ | highlight

debug-echoserver: describe-echoserver
	kubectl -n kube-system get pod -l app=echoserver --output=yaml | highlight


create-npd:
	@printf "create-npd:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy npd$$NC\n"
	@printf "=======================================\n"
	kubectl create -f ./npd/
	@echo ""
	@echo ""
# kubectl get pods --all-namespaces -l app=npd --watch | highlight

apply-npd:
	@printf "create-npd:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy npd$$NC\n"
	@printf "=======================================\n"
	kubectl apply -f ./npd/
	@echo ""
	@echo ""
# kubectl get pods --all-namespaces -l app=npd --watch

delete-npd:
	kubectl delete -f ./npd/

describe-npd:
	kubectl describe -f ./npd/ | highlight

debug-npd: describe-npd
	kubectl -n kube-system get pod -l app=npd --output=yaml | highlight

# install highlight
# https://www.npmjs.com/package/cli-highlight
# npm install -g cli-highlight

debug-cluster:
	@printf "debug-cluster:\n"
	@printf "=======================================\n"
	@printf "$$GREEN kubectl -n kube-system get pods:$$NC\n"
	@printf "=======================================\n"
	kubectl -n kube-system get pods | highlight
	@echo ""
	@echo ""
	@printf "=======================================\n"
	@printf "$$GREEN kubectl get pods --all-namespaces:$$NC\n"
	@printf "=======================================\n"
	kubectl get pods --all-namespaces | highlight
	@echo ""
	@echo ""
	@printf "=======================================\n"
	@printf "$$GREEN kubectl get ingress,services -n=kube-system:$$NC\n"
	@printf "=======================================\n"
	kubectl get ingress,services -n=kube-system | highlight
	@echo ""
	@echo ""
	@printf "=======================================\n"
	@printf "$$GREEN kubectl -n kube-system get po -o wide --sort-by=.spec.nodeName:$$NC\n"
	@printf "=======================================\n"
	kubectl -n kube-system get po -o wide --sort-by=.spec.nodeName | highlight
	@echo ""
	@echo ""
	@printf "=======================================\n"
	@printf "$$GREEN list all services in a cluster and their nodeports:$$NC\n"
	@printf "=======================================\n"
	kubectl get --all-namespaces svc -o json | jq -r '.items[] | [.metadata.name,([.spec.ports[].nodePort | tostring ] | join("|"))] | @csv'
	@echo ""
	@echo ""
	@printf "=======================================\n"
	@printf "$$GREEN kubectl get pods -o wide --all-namespaces --show-all=true --show-labels=true --show-kind=true:$$NC\n"
	@printf "=======================================\n"
	kubectl get pods -o wide --all-namespaces --show-all=true --show-labels=true --show-kind=true | highlight
	@echo ""
	@echo ""
	@printf "=======================================\n"
	@printf "$$GREEN kubectl get nodes --no-headers | grep -v -w 'Ready':$$NC\n"
	@printf "=======================================\n"
	kubectl get nodes --no-headers | grep -v -w 'Ready' | highlight
	@echo ""
	@echo ""
	@printf "=======================================\n"
	@printf "$$GREEN kubectl advance pod status conditions:$$NC\n"
	@printf "=======================================\n"
	kubectl get pods --all-namespaces -o json  | jq -r '.items[] | select(.status.phase != "Running" or ([ .status.conditions[] | select(.type == "Ready" and .state == false) ] | length ) == 1 ) | .metadata.namespace + "/" + .metadata.name'
	@echo ""
	@echo ""
	@printf "=======================================\n"
	@printf "$$GREEN List all not-full-Ready pods:$$NC\n"
	@printf "=======================================\n"
	kubectl get po --all-namespaces | grep -vE '1/1|2/2|3/3' | highlight
	@echo ""
	@echo ""
	@printf "=======================================\n"
	@printf "$$GREEN List all pods without status 'Running':$$NC\n"
	@printf "=======================================\n"
	@kubectl get po --all-namespaces --field-selector status.phase!=Running | highlight
	@echo ""
	@echo ""
	@printf "=======================================\n"
	@printf "$$GREEN List pv,pvc 'Running':$$NC\n"
	@printf "=======================================\n"
	kubectl get pv,pvc | highlight
	@echo ""
	@echo ""
	@printf "=======================================\n"
	@printf "$$GREEN List pv,pvc -n kube-system 'Running':$$NC\n"
	kubectl -n kube-system get pv,pvc | highlight
	@echo ""
	@echo ""


	kubectl get pv,pvc

debug: debug-cluster

# SOURCE: https://github.com/kubernetes/kubernetes/issues/49387
debug-pod-status:
	@kubectl get pods --all-namespaces -o json  | jq -r '.items[] | select(.status.phase != "Running" or ([ .status.conditions[] | select(.type == "Ready" and .state == false) ] | length ) == 1 ) | .metadata.namespace + "/" + .metadata.name'

get-pod-status: debug-pod-status

show-all-pods-not-running:
	@kubectl get pods --all-namespaces --field-selector=status.phase!=Running | highlight

# SOURCE: https://github.com/kubernetes/kubernetes/issues/49387
get-not-ready-pods:
	@kubectl get po --all-namespaces | grep -vE '1/1|2/2|3/3' | highlight

# kubectl get --all-namespaces svc -o json | jq -r '.items[] | [.metadata.name,([.spec.ports[].nodePort | tostring ] | join("|"))] | @csv'
# kubectl get no
# kubectl get po -o wide

kail-no-calico:
	@printf "=======================================\n"
	@printf "$$GREEN Add a big buffer to a pipe between two commands - https://stackoverflow.com/questions/8554568/add-a-big-buffer-to-a-pipe-between-two-commands:$$NC\n"
	@printf "=======================================\n"
	kail --ns kube-system --ignore k8s-app=calico-node | pv -pterbTCB 20k | ccze -A

kail:
	@printf "=======================================\n"
	@printf "$$GREEN Add a big buffer to a pipe between two commands - https://stackoverflow.com/questions/8554568/add-a-big-buffer-to-a-pipe-between-two-commands:$$NC\n"
	@printf "=======================================\n"
	kail --ns kube-system | pv -pterbTCB 20k | ccze -A

export:
	-rm -rfv dump/
	-rm -rfv dump_json_exports/
	@bash ./scripts/kubectl-export.sh
	@kubectl cluster-info dump --all-namespaces --output-directory=./dump_json_exports

log:
	kail --ns kube-system --ignore k8s-app=calico-node | highlight

route:
	ip route list

generate-certs-traefik:
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ingress-traefik/certs/tls.key -out ingress-traefik/certs/tls.crt -subj "/CN=*.hyenaclan.org"
# kubectl -n traefik create secret tls traefik-ui-tls-cert --key ingress-traefik/certs/tls.key --cert ingress-traefik/certs/tls.crt

# SOURCE: https://github.com/kubernetes/dashboard/wiki/Installation#recommended-setup
generate-certs-dashboard:
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout dashboard-ssl/certs/tls.key -out dashboard-ssl/certs/tls.crt -subj "/CN=*.hyenaclan.org"

apply-certs-dashboard:
	@printf "kubectl apply secret generic kubernetes-dashboard-certs:\n"
	@printf "=======================================\n"
	@printf "$$GREEN kubectl apply secret generic kubernetes-dashboard-certs --from-file=dashboard-ssl/certs -n kube-system $$NC\n"
	@printf "=======================================\n"
	kubectl apply secret generic kubernetes-dashboard-certs --from-file=dashboard-ssl/certs -n kube-system | highlight
	@printf "apply-certs-dashboard:\n"
	@printf "=======================================\n"
	@printf "$$GREEN apply-certs-dashboard role $$NC\n"
	@printf "=======================================\n"
	kubectl apply -f ./dashboard-ssl/ | highlight

generate-htpasswd:
	@htpasswd -nb ${_HTPASSWD_USER} ${_HTPASSWD_PASS}

create-ingress-traefik:
	@printf "create-ingress-traefik:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy ingress-traefik$$NC\n"
	@printf "=======================================\n"
	kubectl create -f ./ingress-traefik/
	@echo ""
	@echo ""
	-kubectl -n kube-system create secret tls traefik-ui-tls-cert --key ingress-traefik/certs/tls.key --cert ingress-traefik/certs/tls.crt

redeploy-ingress-traefik:
	@printf "=======================================\n"
	@printf "$$GREEN RUNNING - redeploy-ingress-traefik$$NC\n"
	@printf "=======================================\n"
	@printf "delete-ingress-traefik:\n"
	@printf "=======================================\n"
	@printf "$$GREEN delete ingress-traefik$$NC\n"
	@printf "=======================================\n"
	@echo ""
	@echo ""
	-kubectl delete -f ./ingress-traefik/
	@printf "create-ingress-traefik:\n"
	@printf "=======================================\n"
	@printf "$$GREEN create ingress-traefik$$NC\n"
	@printf "=======================================\n"
	-kubectl create -f ./ingress-traefik/
	@echo ""
	@echo ""
	-kubectl -n kube-system create secret tls traefik-ui-tls-cert --key ingress-traefik/certs/tls.key --cert ingress-traefik/certs/tls.crt


# kubectl get pods --all-namespaces -l app=ingress-traefik --watch | highlight

apply-ingress-traefik:
	@printf "create-ingress-traefik:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy ingress-traefik$$NC\n"
	@printf "=======================================\n"
	kubectl apply -f ./ingress-traefik/
	@echo ""
	@echo ""
# kubectl get pods --all-namespaces -l app=ingress-traefik --watch

delete-ingress-traefik:
	kubectl delete -f ./ingress-traefik/

describe-ingress-traefik:
	kubectl describe -f ./ingress-traefik/ | highlight

debug-ingress-traefik: describe-ingress-traefik
	kubectl -n kube-system get pod -l app=ingress-traefik --output=yaml | highlight

allow-scheduling-on-master:
	kubectl taint node borg-queen-01 node-role.kubernetes.io/master:NoSchedule-

# apk --no-cache add curl
# How to test traefik
# curl -k -H "Authorization: Bearer $token" https://10.100.0.1/version

# NOTE: This is the ip of the master node
add-etc-hosts-cheeses:
	@echo "192.168.1.172 stilton.hyenaclan.org cheddar.hyenaclan.org wensleydale.hyenaclan.org" | sudo tee -a /etc/hosts

show-node-labels:
	kubectl get nodes --show-labels | highlight

create-nfs-server:
	@printf "create-nfs-server:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy nfs-server$$NC\n"
	@printf "=======================================\n"
	kubectl create -f ./nfs-server/
	@echo ""
	@echo ""

apply-nfs-server:
	@printf "create-nfs-server:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy nfs-server$$NC\n"
	@printf "=======================================\n"
	kubectl apply -f ./nfs-server/
	@echo ""
	@echo ""

delete-nfs-server:
	kubectl delete -f ./nfs-server/

describe-nfs-server:
	kubectl describe -f ./nfs-server/ | highlight

debug-nfs-server: describe-nfs-server
	kubectl -n kube-system get pod -l app=nfs-server --output=yaml | highlight



create-nfs-client:
	@printf "create-nfs-client:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy nfs-client$$NC\n"
	@printf "=======================================\n"
	kubectl create -f ./nfs-client/
	@echo ""
	@echo ""
	kubectl describe storageclass | highlight

# https://github.com/kubernetes/kubernetes/blob/3d7d35ee8f099f4611dca06de4453f958b4b8492/cluster/addons/storage-class/local/default.yaml
apply-nfs-client:
	@printf "create-nfs-client:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy nfs-client$$NC\n"
	@printf "=======================================\n"
	kubectl apply -f ./nfs-client/
	@echo ""
	@echo ""
	kubectl describe storageclass | highlight

delete-nfs-client:
	kubectl delete -f ./nfs-client/

describe-nfs-client:
	kubectl describe -f ./nfs-client/ | highlight

debug-nfs-client: describe-nfs-client
	kubectl -n kube-system get pod -l app=nfs-client --output=yaml | highlight

create-registry:
	@printf "create-registry:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy registry$$NC\n"
	@printf "=======================================\n"
	kubectl create -f ./registry/
	@echo ""
	@echo ""
# kubectl get pods --all-namespaces -l app=registry --watch | highlight

apply-registry:
	@printf "create-registry:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy registry$$NC\n"
	@printf "=======================================\n"
	kubectl apply -f ./registry/
	@echo ""
	@echo ""
# kubectl get pods --all-namespaces -l app=registry --watch

delete-registry:
	kubectl delete -f ./registry/

describe-registry:
	kubectl describe -f ./registry/ | highlight

debug-registry: describe-registry
	kubectl -n kube-system get pod -l app=registry --output=yaml | highlight



create-metrics-server:
	@printf "create-metrics-server:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy metrics-server$$NC\n"
	@printf "=======================================\n"
	kubectl create -f ./metrics-server/
	@echo ""
	@echo ""
	kubectl describe storageclass | highlight

# https://github.com/kubernetes/kubernetes/blob/3d7d35ee8f099f4611dca06de4453f958b4b8492/cluster/addons/storage-class/local/default.yaml
apply-metrics-server:
	@printf "create-metrics-server:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy metrics-server$$NC\n"
	@printf "=======================================\n"
	kubectl apply -f ./metrics-server/
	@echo ""
	@echo ""
	kubectl describe storageclass | highlight

delete-metrics-server:
	kubectl delete -f ./metrics-server/

describe-metrics-server:
	kubectl describe -f ./metrics-server/ | highlight

debug-metrics-server: describe-metrics-server
	kubectl -n kube-system get pod -l app=metrics-server --output=yaml | highlight


create-efk:
	@printf "create-efk:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy efk$$NC\n"
	@printf "=======================================\n"
	kubectl create -f ./efk/
	@echo ""
	@echo ""
	kubectl describe storageclass | highlight

# https://github.com/kubernetes/kubernetes/blob/3d7d35ee8f099f4611dca06de4453f958b4b8492/cluster/addons/storage-class/local/default.yaml
apply-efk:
	@printf "create-efk:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy efk$$NC\n"
	@printf "=======================================\n"
	kubectl apply -f ./efk/
	@echo ""
	@echo ""
	kubectl describe storageclass | highlight

delete-efk:
	kubectl delete -f ./efk/

describe-efk:
	kubectl describe -f ./efk/ | highlight

debug-efk: describe-efk
	kubectl -n kube-system get pod -l app=efk --output=yaml | highlight

# SOURCE: https://serverfault.com/questions/77300/tools-to-install-after-a-minimal-linux-install
# TODO: Install these somewhere
# more-ubuntu-tools:
# 	apt-get install openssh-server sudo screen iproute resolvconf \
# 	build-essential tcpdump vlan mii-diag firehol \
# 	apticron atsar ethtool denyhosts rdist bzip2 xclip \
# 	etckeeper git-core less unzip mtr-tiny curl gdebi-core \
# 	xbase-clients rsync psmisc iperf lshw wget pastebinit


create-efk2:
	@printf "create-efk:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy efk$$NC\n"
	@printf "=======================================\n"
	kubectl create -f ./efk2/
	@echo ""
	@echo ""
	kubectl describe storageclass | highlight

# https://github.com/kubernetes/kubernetes/blob/3d7d35ee8f099f4611dca06de4453f958b4b8492/cluster/addons/storage-class/local/default.yaml
apply-efk2:
	@printf "create-efk:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy efk$$NC\n"
	@printf "=======================================\n"
	kubectl apply -f ./efk2/
	@echo ""
	@echo ""
	kubectl describe storageclass | highlight

delete-efk2:
	kubectl delete -f ./efk2/

describe-efk2:
	kubectl describe -f ./efk2/ | highlight

debug-efk2: describe-efk2
	kubectl -n kube-system get pod -l app=efk --output=yaml | highlight

# SOURCE: https://github.com/projectcalico/calico/blob/v3.1.3/v3.1/getting-started/kubernetes/tutorials/stars-policy/index.md
#
create-calico-ui:
	@printf "create-calico-ui:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy calico-ui$$NC\n"
	@printf "=======================================\n"
	kubectl create -f ./calico-ui/
	@echo ""
	@echo ""
# kubectl get pods --all-namespaces -l app=calico-ui --watch | highlight

apply-calico-ui:
	@printf "create-calico-ui:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy calico-ui$$NC\n"
	@printf "=======================================\n"
	kubectl apply -f ./calico-ui/
	@echo ""
	@echo ""
# kubectl get pods --all-namespaces -l app=calico-ui --watch

delete-calico-ui:
	kubectl delete -f ./calico-ui/

describe-calico-ui:
	kubectl describe -f ./calico-ui/ | highlight

debug-calico-ui: describe-calico-ui
	kubectl -n kube-system get pod -l app=calico-ui --output=yaml | highlight

# SOURCE: https://github.com/projectcalico/calico/blob/v3.1.3/v3.1/getting-started/kubernetes/tutorials/stars-policy/index.md
#
create-calico:
	@printf "create-calico:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy calico$$NC\n"
	@printf "=======================================\n"
	kubectl create -f ./calico/
	@echo ""
	@echo ""
# kubectl get pods --all-namespaces -l app=calico --watch | highlight

apply-calico:
	@printf "create-calico:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy calico$$NC\n"
	@printf "=======================================\n"
	kubectl apply -f ./calico/
	@echo ""
	@echo ""
# kubectl get pods --all-namespaces -l app=calico --watch

delete-calico:
	kubectl delete -f ./calico/

describe-calico:
	kubectl describe -f ./calico/ | highlight

debug-calico: describe-calico
	kubectl -n kube-system get pod -l app=calico --output=yaml | highlight


create-elasticsearch-hq:
	@printf "create-elasticsearch-hq:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy elasticsearch-hq$$NC\n"
	@printf "=======================================\n"
	kubectl create -f ./elasticsearch-hq/
	@echo ""
	@echo ""
# kubectl get pods --all-namespaces -l app=elasticsearch-hq --watch | highlight

apply-elasticsearch-hq:
	@printf "create-elasticsearch-hq:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy elasticsearch-hq$$NC\n"
	@printf "=======================================\n"
	kubectl apply -f ./elasticsearch-hq/
	@echo ""
	@echo ""
# kubectl get pods --all-namespaces -l app=elasticsearch-hq --watch

delete-elasticsearch-hq:
	kubectl delete -f ./elasticsearch-hq/

describe-elasticsearch-hq:
	kubectl describe -f ./elasticsearch-hq/ | highlight

debug-elasticsearch-hq: describe-elasticsearch-hq
	kubectl -n kube-system get pod -l app=elasticsearch-hq --output=yaml | highlight


create-elasticsearch-head:
	@printf "create-elasticsearch-head:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy elasticsearch-head$$NC\n"
	@printf "=======================================\n"
	kubectl create -f ./elasticsearch-head/
	@echo ""
	@echo ""
# kubectl get pods --all-namespaces -l app=elasticsearch-head --watch | highlight

apply-elasticsearch-head:
	@printf "create-elasticsearch-head:\n"
	@printf "=======================================\n"
	@printf "$$GREEN deploy elasticsearch-head$$NC\n"
	@printf "=======================================\n"
	kubectl apply -f ./elasticsearch-head/
	@echo ""
	@echo ""
# kubectl get pods --all-namespaces -l app=elasticsearch-head --watch

delete-elasticsearch-head:
	kubectl delete -f ./elasticsearch-head/

describe-elasticsearch-head:
	kubectl describe -f ./elasticsearch-head/ | highlight

debug-elasticsearch-head: describe-elasticsearch-head
	kubectl -n kube-system get pod -l app=elasticsearch-head --output=yaml | highlight

fluentd-bootstrap:
	bash scripts/label-k8-nodes-for-fluentd.sh

label-workers: fluentd-bootstrap

label-nodes: fluentd-bootstrap

create-elasticsearch-index:
	bash scripts/es-create-index.sh

create-index: create-elasticsearch-index

query-es-list-indicies:
	curl -L -XGET 'http://elasticsearch.$(DNSMASQ_DOMAIN)/_cat/indices?v&pretty' | highlight

query-es-allocation-explain:
	curl -L -s -XGET 'http://elasticsearch.$(DNSMASQ_DOMAIN)/_cluster/allocation/explain?pretty' | highlight

enable-shard-allocation:
	curl -XPUT 'http://elasticsearch.$(DNSMASQ_DOMAIN)/_cluster/settings' -d \
	'{ "transient": { "cluster.routing.allocation.enable" : "all" } }'

# https://github.com/mobz/elasticsearch-head/archive/v5.0.0.zip
# https://github.com/mobz/elasticsearch-head/archive/master.zip
# 1  mkdir -p /usr/src/app
# 	2  cd /usr/src/app
# 	3  npm install -g grunt
# 	4  apt-get update; apt-get install curl -y
# 	5  curl -L 'https://github.com/mobz/elasticsearch-head/archive/master.zip' > master.zip
# 	6  file master.zip
# 	7  apt-get install unzip -y
# 	8  unzip master.zip
# 	9  ls
# 10  cd elasticsearch-head-master/
# 11  ls
# 12  apt-get install vim -y
# 13  npm install
# 14  npm audit fix
# 15  grunt server
# 16  npm audit fix --force
# 17  grunt server
# 18  history
# find . -type f -exec sed -i 's/localhost:9200/elasticsearch-logging:9200/g' {} +
