# proto

The versioned `sora.core.v1` gRPC contract is in `sora/core/v1/core_control.proto`.

From the repository root, install Buf and the generators, then run:

```sh
cd proto
buf lint
buf generate
```

Go output is written to `core/gen`. Dart output is written to `app/lib/src/generated`.
The repository workflow and the pull request autofix workflow use the pinned generator versions.
