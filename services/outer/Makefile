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

internal/outerpb/%.pb.go: internal/outerpb/%.proto
	protoc --experimental_allow_proto3_optional --go_out=. --go_opt=paths=source_relative $^

internal/outerpb/%_grpc.pb.go: internal/outerpb/%.proto
	protoc --experimental_allow_proto3_optional --go-grpc_out=. --go-grpc_opt=paths=source_relative $^

bin/outer: $(CMD_GO_FILES) $(PKG_GO_FILES) $(INTERNAL_GO_FILES)
	$(call section, Build outer binary)
	@mkdir -p bin
	go mod tidy
	GOOS=linux GOARCH=amd64 go build -o bin/outer main.go

build: internal/outerpb/definitions.pb.go internal/outerpb/definitions_grpc.pb.go bin/outer

container: build
	$(call section, Build outer image)
	docker buildx build -f Containerfile -t mesh.local/outer:latest --platform linux/amd64 .
