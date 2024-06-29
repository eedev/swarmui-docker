PROJECT_NAME = swarmui
DOCKER_REPOSITORY = eedev/swarmui-docker
TAG=latest
PLATFORM ?= linux/amd64

COMMIT_HASH=$(shell curl -s https://api.github.com/repos/mcmonkeyprojects/SwarmUI/commits/master | jq -r '.sha')
APP_ROOT ?= "/app"

ifeq ($(SWARMUI_USER_ID),)
    SWARMUI_USER_ID := 1000
endif

ifeq ($(SWARMUI_GROUP_ID),)
    SWARMUI_GROUP_ID := 1000
endif

.PHONY: build buildx-build buildx-push buildx-build-amd64 push shell run start stop logs clean release

default: build

build:
	docker build -t $(DOCKER_REPOSITORY):$(TAG) \
		--build-arg COMMIT_HASH=$(COMMIT_HASH) \
		--build-arg SWARMUI_USER_ID=$(SWARMUI_USER_ID) \
		--build-arg SWARMUI_GROUP_ID=$(SWARMUI_GROUP_ID) \
		--build-arg APP_ROOT=$(APP_ROOT) \
		./

# --load doesn't work with multiple platforms https://github.com/docker/buildx/issues/59
# we need to save cache to run tests first.
buildx-build-amd64:
	docker buildx build --platform linux/amd64 -t $(DOCKER_REPOSITORY):$(TAG) \
		--build-arg COMMIT_HASH=$(COMMIT_HASH) \
		--build-arg SWARMUI_USER_ID=$(SWARMUI_USER_ID) \
		--build-arg SWARMUI_GROUP_ID=$(SWARMUI_GROUP_ID) \
		--build-arg APP_ROOT=$(APP_ROOT) \
		--load \
		./

buildx-build:
	docker buildx build --platform $(PLATFORM) -t $(DOCKER_REPOSITORY):$(TAG) \
		--build-arg COMMIT_HASH=$(COMMIT_HASH) \
		--build-arg SWARMUI_USER_ID=$(SWARMUI_USER_ID) \
		--build-arg SWARMUI_GROUP_ID=$(SWARMUI_GROUP_ID) \
		--build-arg APP_ROOT=$(APP_ROOT) \
		./

buildx-push:
	docker buildx build --platform $(PLATFORM) --push -t $(DOCKER_REPOSITORY):$(TAG) \
		--build-arg COMMIT_HASH=$(COMMIT_HASH) \
		--build-arg SWARMUI_USER_ID=$(SWARMUI_USER_ID) \
		--build-arg SWARMUI_GROUP_ID=$(SWARMUI_GROUP_ID) \
		--build-arg APP_ROOT=$(APP_ROOT) \
		./

push:
	docker push $(DOCKER_REPOSITORY):$(TAG)

shell:
	docker run --rm --name $(PROJECT_NAME) -i -t $(PORTS) $(VOLUMES) $(ENV) $(DOCKER_REPOSITORY):$(TAG) /bin/bash

run:
	docker run --rm --name $(PROJECT_NAME) $(PORTS) $(VOLUMES) $(ENV) $(DOCKER_REPOSITORY):$(TAG) $(CMD)

start:
	docker run -d --name $(PROJECT_NAME) $(PORTS) $(VOLUMES) $(ENV) $(DOCKER_REPOSITORY):$(TAG)

stop:
	docker stop $(PROJECT_NAME)

logs:
	docker logs $(PROJECT_NAME)

clean:
	-docker rm -f $(PROJECT_NAME)
	-IMAGE=$(DOCKER_REPOSITORY):$(TAG) docker compose -f compose.yaml down

release: build push