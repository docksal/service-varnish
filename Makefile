-include env_make

VERSION ?= 6.1
TAG ?= $(VERSION)

REPO ?= docksal/varnish
NAME = docksal-varnish-$(VERSION)

BASE_IMAGE_TAG = $(VERSION)

ifneq ($(STABILITY_TAG),)
    ifneq ($(TAG),latest)
        override TAG := $(TAG)-$(STABILITY_TAG)
    endif
endif

.PHONY: build test push shell run start stop logs clean release

default: build

build:
	docker build -t $(REPO):$(TAG) --build-arg VERSION=$(VERSION) .

test:
	cd tests && IMAGE=$(REPO):$(TAG) REPO=$(REPO) NAME=$(NAME) VERSION=$(VERSION) ./test.bats

push:
	docker push $(REPO):$(TAG)

shell:
	docker run --rm --name $(NAME) -i -t $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) /bin/bash

run:
	docker run --rm --name $(NAME) -e DEBUG=1 $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) $(CMD)

start:
	docker run -d --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG)

stop:
	docker stop $(NAME)

logs:
	docker logs $(NAME)

clean:
	docker rm -f $(NAME) || true

release: build push
