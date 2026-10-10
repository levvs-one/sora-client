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

Contract 1.6 adds authenticated `GetSubscriptionLink` for opening a subscription page.
Subscription states omit the bearer link; clients request it only for this action and never cache or log it.

Contract 1.7 adds an explicit TUN stack to SessionPlan. Clients negotiate 1.7
before sending it; older peers remain usable for plans without this field.
