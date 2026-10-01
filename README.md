# Elixir Observer

Smarter package insights for the Elixir Ecosystem

## Setup

1. Run `cp .env.sample .env`
2. Generate a Github token [here](https://github.com/settings/tokens) with no scopes. Add token to `.env` file.
3. Run `iex -S mix`
4. Run `Toolbox.Tasks.Hexpm.run()`
5. Run `Toolbox.Tasks.SCM.run()`

## Porthole (inspecting production)

[Porthole](https://github.com/mimiquate/porthole) lets coding agents inspect
the live cluster with read-only SQL. This app only carries Porthole's
collectors (the `:porthole` dependency); queries are served by a separate
sidecar Fly app, `ex-tools-porthole`, built and configured from the Porthole
repository. Follow [Deploying the sidecar on Fly.io](https://github.com/mimiquate/porthole/blob/main/guides/deploy-fly.md)
with these values for ex-tools:

```console
$ fly deploy . \
    --config sidecar/fly.toml \
    --dockerfile sidecar/Dockerfile \
    --app ex-tools-porthole \
    --primary-region ewr \
    --ha=false \
    --build-arg ELIXIR_VERSION=1.18.4 \
    --build-arg OTP_VERSION=28.1 \
    --build-arg DEBIAN_VERSION=bookworm-20260610-slim \
    --env DNS_CLUSTER_QUERY=ex-tools.internal
```

Run it from a Porthole checkout at the revision in this app's `mix.lock`.
The sidecar's secrets are `RELEASE_COOKIE` (the same value as ex-tools') and
`PORTHOLE_TOKENS`. To use it:

```console
$ fly proxy 4040:4040 -a ex-tools-porthole
$ claude mcp add --transport http ex-tools-porthole http://localhost:4040/ \
    --header "Authorization: Bearer <your token>"
```

When the Elixir/OTP versions in `.tool-versions` change, update the build
args above to match.
