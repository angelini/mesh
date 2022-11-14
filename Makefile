MAKEFLAGS += -j2

ROOT_DIR = $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

K8S_VERSION := 1.25
K3S_VERSION := 1.25.3+k3s1
JSONNET_VERSION := 0.19.1
KUBECONFORM_VERSION := 0.5.0

CTR := sudo bin/k3s ctr
KC := bin/k3s kubectl

.PHONY: install start-k3s build import-containers build-k8s-resources
.PHONY: deploy teardown status

define section
	@echo ""
	@echo "--------------------------------"
	@echo "| $(1)"
	@echo "--------------------------------"
	@echo ""
endef

bin/k3s:
	@mkdir -p bin
	curl -fsSL -o bin/k3s https://github.com/k3s-io/k3s/releases/download/v$(K3S_VERSION)/k3s
	chmod +x bin/k3s

install: bin/k3s
	go install github.com/google/go-jsonnet/cmd/jsonnet@v$(JSONNET_VERSION)
	go install github.com/google/go-jsonnet/cmd/jsonnet-lint@v$(JSONNET_VERSION)
	go install github.com/google/go-jsonnet/cmd/jsonnetfmt@v$(JSONNET_VERSION)
	go install github.com/yannh/kubeconform/cmd/kubeconform@v$(KUBECONFORM_VERSION)
	go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28
	go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2

	@mkdir -p lib
	go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest
	jb install --jsonnetpkg-home=lib github.com/jsonnet-libs/k8s-libsonnet/$(K8S_VERSION)@main

start-k3s:
	sudo bin/k3s server -c $(ROOT_DIR)/k3s_config.yaml

build:
	cd envoy; make install
	cd services/inner; make build
	cd services/outer; make build

import-containers:
	@sudo echo "Ensure sudo"
	cd envoy; make container
	buildah push mesh.local/envoy:latest oci-archive:envoy.tar:latest
	$(CTR) images import --base-name mesh.local/envoy --digests ./envoy.tar
	@rm envoy.tar

	cd services/inner; make container
	buildah push mesh.local/inner:latest oci-archive:inner.tar:latest
	$(CTR) images import --base-name mesh.local/inner --digests ./inner.tar
	@rm inner.tar

	cd services/outer; make container
	buildah push mesh.local/outer:latest oci-archive:outer.tar:latest
	$(CTR) images import --base-name mesh.local/outer --digests ./outer.tar
	@rm outer.tar

k8s/global/namespace.yaml: k8s/global/namespace.jsonnet
	jsonnet -y -J lib/ k8s/global/namespace.jsonnet > k8s/global/namespace.yaml

k8s/inner/main.yaml: k8s/inner/main.jsonnet
	jsonnet -y -J lib/ k8s/inner/main.jsonnet > k8s/inner/main.yaml

k8s/outer/main.yaml: k8s/outer/main.jsonnet
	jsonnet -y -J lib/ k8s/outer/main.jsonnet > k8s/outer/main.yaml

k8s/front-proxy/main.yaml: k8s/front-proxy/main.jsonnet
	jsonnet -y -J lib/ k8s/front-proxy/main.jsonnet > k8s/front-proxy/main.yaml

build-k8s-resources: k8s/global/namespace.yaml k8s/inner/main.yaml k8s/outer/main.yaml k8s/front-proxy/main.yaml
	kubeconform -kubernetes-version 1.25.0 -summary -strict $^

teardown:
	@$(KC) -n mesh delete all --all --force --grace-period=0 1> /dev/null

deploy: teardown import-containers build-k8s-resources
	$(call section, Deploy K8S resources)
	$(KC) apply -f k8s/global/namespace.yaml
	$(KC) -n mesh apply -f k8s/inner/main.yaml
	$(KC) -n mesh apply -f k8s/outer/main.yaml
	$(KC) -n mesh apply -f k8s/front-proxy/main.yaml

status:
	@$(KC) -n mesh get pods -o wide
	@echo ""
	@$(KC) -n mesh get services
