SWARMUI_VER ?= 0.9.0.1-Beta
SWARMUI_VER_MINOR ?= $(shell echo "${SWARMUI_VER}" | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')

REPO = eedev/swarmui-docker
NAME = swarmui

PLATFORM ?= linux/amd64

ifeq ($(SWARMUI_USER_ID),)
    SWARMUI_USER_ID := 1000
endif

ifeq ($(SWARMUI_GROUP_ID),)
    SWARMUI_GROUP_ID := 1000
endif

ifeq ($(TAG),)
    ifneq ($(SWARMUI_DEV),)
    	TAG ?= $(SWARMUI_VER_MINOR)-dev
    else
        TAG ?= $(SWARMUI_VER_MINOR)
    endif
endif

ifneq ($(SWARMUI_DEV),)
    NAME := $(NAME)-dev
endif

ifneq ($(STABILITY_TAG),)
    ifneq ($(TAG),latest)
        override TAG := $(TAG)-$(STABILITY_TAG)
    endif
endif

.PHONY: build buildx-build buildx-push buildx-build-amd64 test push shell run start stop logs clean release

default: build

build:
	docker build -t $(REPO):$(TAG) \
		--build-arg SWARMUI_VER=$(SWARMUI_VER) \
		--build-arg SWARMUI_DEV=$(SWARMUI_DEV) \
		--build-arg SWARMUI_USER_ID=$(SWARMUI_USER_ID) \
		--build-arg SWARMUI_GROUP_ID=$(SWARMUI_GROUP_ID) \
		./

# --load doesn't work with multiple platforms https://github.com/docker/buildx/issues/59
# we need to save cache to run tests first.
buildx-build-amd64:
	docker buildx build --platform linux/amd64 -t $(REPO):$(TAG) \
		--build-arg SWARMUI_VER=$(SWARMUI_VER) \
		--build-arg SWARMUI_DEV=$(SWARMUI_DEV) \
		--build-arg SWARMUI_USER_ID=$(SWARMUI_USER_ID) \
		--build-arg SWARMUI_GROUP_ID=$(SWARMUI_GROUP_ID) \
		--load \
		./

buildx-build:
	docker buildx build --platform $(PLATFORM) -t $(REPO):$(TAG) \
		--build-arg SWARMUI_VER=$(SWARMUI_VER) \
		--build-arg SWARMUI_DEV=$(SWARMUI_DEV) \
		--build-arg SWARMUI_USER_ID=$(SWARMUI_USER_ID) \
		--build-arg SWARMUI_GROUP_ID=$(SWARMUI_GROUP_ID) \
		./

buildx-push:
	docker buildx build --platform $(PLATFORM) --push -t $(REPO):$(TAG) \
		--build-arg SWARMUI_VER=$(SWARMUI_VER) \
		--build-arg SWARMUI_DEV=$(SWARMUI_DEV) \
		--build-arg SWARMUI_USER_ID=$(SWARMUI_USER_ID) \
		--build-arg SWARMUI_GROUP_ID=$(SWARMUI_GROUP_ID) \
		./

test:
	cd ./tests && IMAGE=$(REPO):$(TAG) ./run.sh

push:
	docker push $(REPO):$(TAG)

shell:
	docker run --rm --name $(NAME) -i -t $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) /bin/bash

run:
	docker run --rm --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) $(CMD)

start:
	docker run -d --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG)

stop:
	docker stop $(NAME)

logs:
	docker logs $(NAME)

clean:
	-docker rm -f $(NAME)
	-IMAGE=$(REPO):$(TAG) docker-compose -f compose.yaml down

release: build push