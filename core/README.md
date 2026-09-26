# core

`core` is the Go module for Sora's privileged network core. The local control API
is generated from `proto/sora/core/v1/core_control.proto`.

From the repository root, generate the checked-in Go and Dart artifacts with:

```sh
go install github.com/bufbuild/buf/cmd/buf@v1.50.0
go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.36.5
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.5.1
buf generate --template proto/buf.gen.yaml proto
```

The Go contract tests are in `core/control`. Run them with `go test ./...` from
this directory. Generated files are maintained by CI and the pull request autofix workflow.
