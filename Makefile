MAKEFLAGS += -j2

ROOT_DIR = $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

K8S_VERSION := 1.25
K3S_VERSION := 1.25.3+k3s1
JSONNET_VERSION := 0.19.1
KUBECONFORM_VERSION := 0.5.0

CTR := sudo bin/k3s ctr
KC_NO_NS := kubectl
KC := kubectl -n mesh

.PHONY: install start-k3s build containers build-k8s-resources
.PHONY: deploy teardown status logs

define section
	@echo ""
	@echo "--------------------------------"
	@echo "| $(1)"
	@echo "--------------------------------"
	@echo ""
endef

install:
	go install github.com/google/go-jsonnet/cmd/jsonnet@v$(JSONNET_VERSION)
	go install github.com/google/go-jsonnet/cmd/jsonnet-lint@v$(JSONNET_VERSION)
	go install github.com/google/go-jsonnet/cmd/jsonnetfmt@v$(JSONNET_VERSION)
	go install github.com/yannh/kubeconform/cmd/kubeconform@v$(KUBECONFORM_VERSION)
	go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28
	go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2

	@mkdir -p lib
	go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest
	jb install --jsonnetpkg-home=lib github.com/jsonnet-libs/k8s-libsonnet/$(K8S_VERSION)@main

build:
	cd envoy; make install
	cd services/inner; make build
	cd services/outer; make build

containers: build
	cd envoy; make container
	cd services/inner; make container
	cd services/outer; make container

dev/local.key:
	@mkdir -p dev
	mkcert -cert-file dev/local.cert -key-file dev/local.key localhost 127.0.0.1 ::1

dev/local.cert: dev/local.key

k8s/global/namespace.yaml: k8s/global/namespace.jsonnet
	jsonnet -y -J lib/ k8s/global/namespace.jsonnet > k8s/global/namespace.yaml

k8s/inner/main.yaml: k8s/inner/main.jsonnet
	jsonnet -y -J lib/ k8s/inner/main.jsonnet > k8s/inner/main.yaml

k8s/outer/main.yaml: k8s/outer/main.jsonnet
	jsonnet -y -J lib/ k8s/outer/main.jsonnet > k8s/outer/main.yaml

k8s/front-proxy/main.yaml: k8s/front-proxy/main.jsonnet
	jsonnet -y -J lib/ k8s/front-proxy/main.jsonnet > k8s/front-proxy/main.yaml

build-k8s-resources: dev/local.cert k8s/global/namespace.yaml k8s/inner/main.yaml k8s/outer/main.yaml k8s/front-proxy/main.yaml
	kubeconform -kubernetes-version 1.25.0 -summary -strict $^

teardown:
	@$(KC) delete all --all --force --grace-period=0 1> /dev/null
	@$(KC) delete secret --ignore-not-found tls-secret 1> /dev/null
	@$(KC) delete configmap --ignore-not-found front-proxy-envoy-config 1> /dev/null
	@$(KC) delete configmap --ignore-not-found outer-envoy-config 1> /dev/null
	@$(KC) delete configmap --ignore-not-found inner-envoy-config 1> /dev/null

deploy: teardown containers build-k8s-resources
	$(call section, Deploy K8S resources)
	$(KC_NO_NS) apply -f k8s/global/namespace.yaml
	$(KC) create secret tls tls-secret --cert=dev/local.cert --key=dev/local.key
	$(KC) create configmap front-proxy-envoy-config --from-file=config.yaml=envoy/config.yaml
	$(KC) create configmap outer-envoy-config --from-file=config.yaml=services/outer/envoy-config.yaml
	$(KC) create configmap inner-envoy-config --from-file=config.yaml=services/inner/envoy-config.yaml
	$(KC) apply -f k8s/inner/main.yaml
	$(KC) apply -f k8s/outer/main.yaml
	$(KC) apply -f k8s/front-proxy/main.yaml

status:
	@$(KC) get pods -o wide
	@echo ""
	@$(KC) get services

name ?= front-proxy

logs:
	@$(KC) logs -f $(shell $(KC) -n mesh get pods -l name=$(name) -o jsonpath='{range .items[*]}{"\n"}{.metadata.name}{end}')
