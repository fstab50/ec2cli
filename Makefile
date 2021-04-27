#
#	 PROJECT:  ec2cli
#	 Makefile, version shell 2.0
#
# --- declarations  --------------------------------------------------------------------------------


PROJECT := ec2cli
CUR_DIR = $(shell pwd)
VENV_DIR := $(CUR_DIR)/p3_venv
LIB_DIR = $(CUR_DIR)/core
SCRIPT_DIR := $(CUR_DIR)/scripts
PYTHON_VERSION := python3
PYTHON3_PATH := $(shell which $(PYTHON_VERSION))
BUILDDEB_ROOT = $(CUR_DIR)/packaging/deb
BUILDRPM_ROOT = $(CUR_DIR)/packaging/rpm
GIT := $(shell which git)
DOCKER := $(shell which docker)
PIP_CALL := $(VENV_DIR)/bin/pip3
ACTIVATE = $(shell . $(VENV_DIR)/bin/activate)
MAKE = $(shell which make)
MODULE_PATH := $(LIB_DIR)
DOC_PATH := $(CUR_DIR)/docs
REQUIREMENT = $(CUR_DIR)/requirements.txt
VERSION_FILE = $(LIB_DIR)/version.py


# --- rollup targets  ------------------------------------------------------------------------------


.PHONY: zero-builddeb zero-buildrpm  zero-installdeb zero-installrpm

build-all: clean builddeb buildrpm    ## Clean and Build Debian & RPM pkgs

zero-builddeb: clean generate-regions builddeb    ## Clean and Build Debian (.deb) pkg

zero-buildrpm: clean generate-regions buildrpm    ## Clean and Build Redhat (.rpm) pkg

zero-installdeb:	clean builddeb installdeb	## Clean, Build & Install Debian (.deb) pkg

zero-installrpm: clean buildrpm installrpm    ## Clean, Build & Install Redhat (.rpm) pkg


# --- targets -------------------------------------------------------------------------------------


.PHONY: pre-build
pre-build:    ## Remove residual build artifacts
	rm -rf $(CUR_DIR)/dist
	mkdir $(CUR_DIR)/dist


setup-venv: $(VENV_DIR)

$(VENV_DIR):  pre-build   ## Create and activiate python venv
	$(PYTHON3_PATH) -m venv $(VENV_DIR); \
	. $(VENV_DIR)/bin/activate && $(PIP_CALL) install -U setuptools pip && \
	$(PIP_CALL) install -r $(REQUIREMENT);


.PHONY: test
test:     ## Run pytest unittests
	@echo "Executing Tests..."; \
	if [ $(PDB) ]; then PDB = "true"; \
	bash $(CUR_DIR)/scripts/make-test.sh $(CUR_DIR) $(VENV_DIR) $(MODULE_PATH) $(PDB); \
	elif [ $(MODULE) ]; then PDB = "false"; \
	bash $(CUR_DIR)/scripts/make-test.sh $(CUR_DIR) $(VENV_DIR) $(MODULE_PATH) $(PDB) $(MODULE); \
	elif [ $(COMPLEXITY) ]; then COMPLEXITY = "run"; \
	bash $(CUR_DIR)/scripts/make-test.sh $(CUR_DIR) $(VENV_DIR) $(MODULE_PATH) $(COMPLEXITY) $(MODULE); \
	else bash $(CUR_DIR)/scripts/make-test.sh $(CUR_DIR) $(VENV_DIR) $(MODULE_PATH); fi


.PHONY: build-sizes
build-sizes:	## Create ec2 sizes.txt if 10 days age. FORCE=true trigger refresh
	cp $(MODULE_PATH)/version.py $(SCRIPT_DIR)/
	if [ -d $(VENV_DIR) ]; then . $(VENV_DIR)/bin/activate && \
	$(PYTHON3_PATH) $(SCRIPT_DIR)/ec2sizes.py $(FORCE); else \
	$(MAKE) setup-venv && . $(VENV_DIR)/bin/activate && \
	$(PYTHON3_PATH) $(SCRIPT_DIR)/ec2sizes.py $(FORCE); fi
	rm -f $(SCRIPT_DIR)/version.py


.PHONY: generate-regions
generate-regions:  ## Regenerate list of AWS region codes
	if [ -d $(VENV_DIR) ]; then . $(VENV_DIR)/bin/activate && \
	$(PYTHON3_PATH) $(SCRIPT_DIR)/regions.py; else \
	$(MAKE) setup-venv && . $(VENV_DIR)/bin/activate && \
	$(PYTHON3_PATH) $(SCRIPT_DIR)/regions.py; fi


docs: clean setup-venv    ## Generate sphinx documentation
	. $(VENV_DIR)/bin/activate && \
	$(PIP_CALL) install -r $(DOC_PATH)/requirements.txt
	cd $(CUR_DIR) && $(MAKE) clean-docs
	cd $(DOC_PATH) && . $(VENV_DIR)/bin/activate && $(MAKE) html


.PHONY: builddeb
builddeb:  clean setup-venv  ## Build Debian distribution (.deb) os package
	@echo "Building Debian package format of $(PROJECT)"; \
	cp $(VERSION_FILE) $(SCRIPT_DIR)/ ; \
	cp $(CUR_DIR)/bash/components.py $(LIB_DIR)/ ; \
	if [ ! -d $(VENV_DIR) ]; then $(MAKE) setup-venv; fi; \
	if [ $(VERSION) ]; then . $(VENV_DIR)/bin/activate && \
	$(PYTHON3_PATH) $(SCRIPT_DIR)/builddeb.py --build --set-version $(VERSION); \
	else cd $(CUR_DIR) && . $(VENV_DIR)/bin/activate && $(PYTHON3_PATH) $(SCRIPT_DIR)/builddeb.py --build; fi


.PHONY: buildrpm
buildrpm:  setup-venv   ## Build Redhat distribution (.rpm) os package
	@echo "Building RPM package format of $(PROJECT)"; \
	cp $(CUR_DIR)/bash/components.py $(LIB_DIR)/ ; \
	if [ $(VERSION) ]; then cd $(CUR_DIR) && . $(VENV_DIR)/bin/activate && \
	$(PYTHON3_PATH) $(SCRIPT_DIR)/buildrpm.py --build --set-version $(VERSION); else \
	cd $(CUR_DIR) && . $(VENV_DIR)/bin/activate && $(PYTHON3_PATH) $(SCRIPT_DIR)/buildrpm.py --build; fi; \
	rm $(LIB_DIR)/components.py;


.PHONY: installdeb
installdeb: builddeb   ## Install (source: pypi). Build artifacts exist
	if [ ! -d $(VENV_DIR) ]; then $(MAKE) setup-venv; fi; \
	cd $(CUR_DIR) && . $(VENV_DIR)/bin/activate && bash $(SCRIPT_DIR)/installdeb.sh


.PHONY: installrpm
installrpm: buildrpm   ## Install (source: pypi). Build artifacts exist
	if [ ! -d $(VENV_DIR) ]; then $(MAKE) setup-venv; fi; \
	cd $(CUR_DIR) && . $(VENV_DIR)/bin/activate && bash $(SCRIPT_DIR)/installrpm.sh


.PHONY: rebuild-docs
rebuild-docs:   ##  Regenerate sphinx documentation
	cd $(CUR_DIR)/docs && . $(VENV_DIR)/bin/activate && $(MAKE) html && cd $(CUR_DIR);


.PHONY: upload-images
upload-images:   ## Upload README images to Amazon S3
	bash $(CUR_DIR)/scripts/s3upload.sh


.PHONY: help
help:   ## Print help index
	@printf "\n\033[0m %-15s\033[0m %-13s\u001b[37;1m%-15s\u001b[0m\n\n" " " "make targets: " $(PROJECT)
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[0m%-2s\033[36m%-20s\033[33m %-8s\033[0m%-5s\n\n"," ", $$1, "-->", $$2}' $(MAKEFILE_LIST)
	@printf "\u001b[37;0m%-2s\u001b[37;0m%-2s\n\n" " " "______________________________________________________________________"
	@printf "\u001b[37;1m%-3s\u001b[37;1m%-3s\033[0m %-6s\u001b[44;1m%-9s\u001b[37;0m%-15s\n\n" " " "  make" "zero-build[deb|rpm] " "VERSION=X" " to build specific version id"


.PHONY: debian-help
debian-help:  ## print help menu options for the debian package creation script
	cp $(MODULE_PATH)/version.py $(SCRIPT_DIR)/
	$(PYTHON3_PATH) $(SCRIPT_DIR)/builddeb.py
	rm -f $(SCRIPT_DIR)/version.py


.PHONY: rpm-help
rpm-help:  ## print help menu options for the redhat rpm package creation script
	$(PYTHON3_PATH) $(SCRIPT_DIR)/buildrpm.py


.PHONY: clean-docs
clean-docs:    ## Remove build artifacts for documentation only
	@echo "Clean docs build"
	if [ -d $(VENV_DIR) ]; then . $(VENV_DIR)/bin/activate && \
	cd $(DOC_PATH) && $(MAKE) clean || true; fi


.PHONY: clean
clean:  ## Remove all build artifacts generated by make
	@echo "Clean build artifacts"
	rm -rf $(VENV_DIR) || true
	rm -rf $(CUR_DIR)/dist || true
	rm -rf $(CUR_DIR)/*.egg-info || true
	rm -rf $(SCRIPT_DIR)/__pycache__ || true
	rm -rf $(LIB_DIR)/__pycache__ || true
	rm -rf $(CUR_DIR)/tests/__pycache__ || true
	rm -rf $(CUR_DIR)/.pytest_cache || true
	rm -f $(SCRIPT_DIR)/version.py || true
	rm -fr $(BUILDDEB_ROOT)/ec2cli-*_amd64
