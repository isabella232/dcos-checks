DEFAULT_TARGET: build

VERSION := 1.1
COMMIT := $(shell git rev-parse --short HEAD)
LDFLAGS := -X github.com/dcos/dcos-checks/config.Version=$(VERSION) -X github.com/dcos/dcos-checks/config.Commit=$(COMMIT)

CURRENT_DIR=$(shell pwd)
BUILD_DIR=build
PKG_DIR=/dcos-checks
BINARY_NAME=dcos-checks
IMAGE_NAME=dcos-checks
SRCS := $(shell find . -type f -name '*.go' -not -path './vendor/*')

.PHONY: docker
docker:
ifndef NO_DOCKER
	docker build -t $(IMAGE_NAME) .
endif

$(BUILD_DIR)/$(BINARY_NAME): $(SRCS)
	mkdir -p $(BUILD_DIR)
	$(call inDocker,go build -mod=vendor -v -ldflags '$(LDFLAGS)' -o $(BUILD_DIR)/$(BINARY_NAME))

.PHONY: build
build: docker $(BUILD_DIR)/$(BINARY_NAME)

# install does not run in a docker container to build for the correct OS
.PHONY: install
install:
	go install -mod=vendor -v -ldflags '$(LDFLAGS)'

.PHONY: test
test: docker
	$(call inDocker,bash -x -c 'go test -mod=vendor ./...')

.PHONY: integration
integration:
	@echo "This project doesn't have any integration tests"

.PHONY: publish
publish:
	@echo "This project doesn't have any artifacts to be published"

.PHONY: clean
clean:
	rm -rf ./$(BUILD_DIR)

ifdef NO_DOCKER
  define inDocker
    $1
  endef
else
  define inDocker
    docker run \
      $(shell test -t 0 && echo "-t -i" || true) \
      -v $(CURRENT_DIR):$(PKG_DIR) \
      -w $(PKG_DIR) \
      --rm \
      $(IMAGE_NAME) \
      $1
  endef
endif
