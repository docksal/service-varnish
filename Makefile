DOCKER ?= docker

VERSION ?= 7.0
TAG ?= $(VERSION)

REPO ?= docksal/varnish
NAME = docksal-varnish-$(VERSION)

BASE_IMAGE_TAG = $(VERSION)

ifneq ($(STABILITY_TAG),)
	ifneq ($(TAG),latest)
		override TAG := $(TAG)-$(STABILITY_TAG)
	endif
endif

-include tests/env_make

.EXPORT_ALL_VARIABLES:

.PHONY: build test push shell run start stop logs clean release

default: build

build:
	$(DOCKER) build -t $(REPO):$(TAG) --build-arg VERSION=$(VERSION) .

test:
	IMAGE=$(REPO):$(TAG) REPO=$(REPO) NAME=$(NAME) VERSION=$(VERSION) tests/test.bats

push:
	$(DOCKER) push $(REPO):$(TAG)

start-dependencies:
	$(DOCKER) network create varnish
	$(DOCKER) run -d --name $(NAME)-web -p 2581:80 --network=varnish -v $(PWD)/tests/docroot:/var/www/docroot docksal/apache

shell: clean start-dependencies
	$(DOCKER) run --rm --name $(NAME) -i -t --network=varnish $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) /bin/bash

run: clean start-dependencies
	$(DOCKER) run --rm --name $(NAME) -e DEBUG=1 --network=varnish $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) $(CMD)

start: clean start-dependencies
	$(DOCKER) run -d --name $(NAME) --network=varnish $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG)

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

clean:
	$(DOCKER) rm -f $(NAME) || true
	$(DOCKER) rm -f $(NAME)-web || true
	$(DOCKER) network remove varnish || true
	rm -f tests/docroot/index2.html || true

release: build push
