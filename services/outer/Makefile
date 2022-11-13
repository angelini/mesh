define section
	@echo ""
	@echo "--------------------------------"
	@echo "| $(1)"
	@echo "--------------------------------"
	@echo ""
endef

.PHONY: build container

internal/pb/%.pb.go: internal/pb/%.proto
	protoc --experimental_allow_proto3_optional --go_out=. --go_opt=paths=source_relative $^

internal/pb/%_grpc.pb.go: internal/pb/%.proto
	protoc --experimental_allow_proto3_optional --go-grpc_out=. --go-grpc_opt=paths=source_relative $^

bin/outer:
	$(call section, Build outer binary)
	@mkdir -p bin
	go build -o bin/outer main.go

build: internal/pb/definitions.pb.go internal/pb/definitions_grpc.pb.go bin/outer

container: export BUILDAH_LAYERS=true
container: build
	$(call section, Build outer image)
	buildah build -f Containerfile -t mesh.local/outer:latest
