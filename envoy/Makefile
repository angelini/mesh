ENVOY_VERSION := 1.24.0

define section
	@echo ""
	@echo "--------------------------------"
	@echo "| $(1)"
	@echo "--------------------------------"
	@echo ""
endef

.PHONY: install container

bin/envoy:
	@mkdir -p bin
	curl -fsSL -o bin/envoy https://github.com/envoyproxy/envoy/releases/download/v$(ENVOY_VERSION)/envoy-1.24.0-linux-x86_64
	chmod +x bin/envoy

install: bin/envoy

container: install
	$(call section, Build envoy image)
	docker buildx build -f Containerfile -t mesh.local/envoy:latest --platform linux/amd64 .

