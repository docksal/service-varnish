# Load test variables
-include tests/env_make

# Allow using a different docker binary
DOCKER ?= docker

# Force BuildKit mode for builds
# See https://docs.docker.com/buildx/working-with-buildx/
DOCKER_BUILDKIT=1

IMAGE ?= docksal/varnish
VERSION ?= 7.0
UPSTREAM_IMAGE ?= varnish:$(VERSION)
BUILD_IMAGE_TAG ?= $(IMAGE):$(VERSION)-build
NAME = docksal-varnish-$(VERSION)

# Make it possible to pass arguments to Makefile from command line
# https://stackoverflow.com/a/6273809/1826109
ARGS = $(filter-out $@,$(MAKECMDGOALS))

.EXPORT_ALL_VARIABLES:

.PHONY: build test push shell run start stop logs clean

default: build

build:
	$(DOCKER) build -t $(BUILD_IMAGE_TAG) --build-arg UPSTREAM_IMAGE=$(UPSTREAM_IMAGE) --build-arg VERSION=$(VERSION) .

test:
	IMAGE=$(BUILD_IMAGE_TAG) NAME=$(NAME) VERSION=$(VERSION) ./tests/test.bats

push:
	$(DOCKER) push $(BUILD_IMAGE_TAG)

start-dependencies:
	$(DOCKER) network create varnish
	$(DOCKER) run -d --name $(NAME)-web -p 2581:80 --network=varnish -v $(PWD)/tests/docroot:/var/www/docroot docksal/apache:2.4-2.4

shell: clean start-dependencies
	$(DOCKER) run --rm --name $(NAME) -it --network=varnish $(PORTS) $(VOLUMES) $(ENV) $(BUILD_IMAGE_TAG) /bin/bash

run: clean start-dependencies
	$(DOCKER) run --rm --name $(NAME) -it -e DEBUG=1 --network=varnish $(PORTS) $(VOLUMES) $(ENV) $(BUILD_IMAGE_TAG) $(CMD)

start: clean start-dependencies
	$(DOCKER) run -d --name $(NAME) --network=varnish $(PORTS) $(VOLUMES) $(ENV) $(BUILD_IMAGE_TAG)

exec:
	$(DOCKER) exec $(NAME) bash -lc '$(CMD)'

exec-it:
	$(DOCKER) exec -it $(NAME) bash -lic '$(CMD)'

stop:
	$(DOCKER) stop $(NAME)
	$(DOCKER) stop $(NAME)-web

logs:
	$(DOCKER) logs $(NAME)

logs-follow:
	$(DOCKER) logs -f $(NAME)

debug: build start logs-follow

clean:
	$(DOCKER) rm -f $(NAME) || true
	$(DOCKER) rm -f $(NAME)-web || true
	$(DOCKER) network remove varnish || true
	rm -f tests/docroot/index2.html || true

# Make it possible to pass arguments to Makefile from command line
# https://stackoverflow.com/a/6273809/1826109
%:
	@:
