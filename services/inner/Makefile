define section
	@echo ""
	@echo "--------------------------------"
	@echo "| $(1)"
	@echo "--------------------------------"
	@echo ""
endef

.PHONY: build container

CMD_GO_FILES := $(shell find cmd/ -type f -name '*.go')
PKG_GO_FILES := $(shell find pkg/ -type f -name '*.go')
INTERNAL_GO_FILES := $(shell find internal/ -type f -name '*.go')

internal/innerpb/%.pb.go: internal/innerpb/%.proto
	protoc --experimental_allow_proto3_optional --go_out=. --go_opt=paths=source_relative $^

internal/innerpb/%_grpc.pb.go: internal/innerpb/%.proto
	protoc --experimental_allow_proto3_optional --go-grpc_out=. --go-grpc_opt=paths=source_relative $^

bin/inner: $(CMD_GO_FILES) $(PKG_GO_FILES) $(INTERNAL_GO_FILES)
	$(call section, Build inner binary)
	@mkdir -p bin
	go mod tidy
	GOOS=linux GOARCH=amd64 go build -o bin/inner main.go

build: internal/innerpb/definitions.pb.go internal/innerpb/definitions_grpc.pb.go bin/inner

container: build
	$(call section, Build inner image)
	docker buildx build -f Containerfile -t mesh.local/inner:latest --platform linux/amd64 .
