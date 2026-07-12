# SDK Demo Backend

Tiny Lua game running on the [asobi_lua](https://github.com/widgrensit/asobi_lua) Docker image. This is the canonical backend the [Asobi SDK demos](https://github.com/widgrensit/asobi#sdks) point at, and the repo `asobi init --template backend` fetches when you want a complete, runnable backend to copy from.

It exists so SDK quickstarts have one command (`docker compose up -d`) instead of "install Erlang, install rebar3, run migrations, then run an Erlang shell."

## Quick Start

```bash
git clone https://github.com/widgrensit/sdk_demo_backend.git
cd sdk_demo_backend
docker compose up -d
```

Or scaffold a fresh copy with the CLI:

```bash
asobi init mybackend --template backend
cd mybackend
docker compose up -d
```

## Managed vs local

Two ways to run an Asobi backend, on opposite sides of the credential boundary:

- **Local (this repo).** `docker compose up -d` runs the public `asobi_lua` image against your own Postgres. No account, no keys. Configured entirely by the `ASOBI_*` environment variables in `docker-compose.yml`. This is the honest self-host on-ramp.
- **Managed (Asobi Cloud).** `asobi login` then `asobi deploy <env> lua` ships just your `lua/` to a hosted, EU-sovereign environment. The platform owns Postgres, TLS, and the runtime config. See [asobi.dev/docs/cloud](https://asobi.dev/docs/cloud).

Same `lua/`, same wire protocol - the only difference is who runs Postgres and holds the config. There is no `sys.config` here on purpose: a compose deployment is tuned through container env vars, not the OTP release config. That file only exists if you build the release from source (see [asobi.dev/docs/self-host](https://asobi.dev/docs/self-host)).

The backend listens on `http://localhost:8084` (HTTP + WebSocket on `/ws`).

Verify by registering a throwaway player:

```bash
curl -X POST http://localhost:8084/api/v1/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"username":"smoke","password":"smoke1234","display_name":"Smoke"}'
```

You should get a `200` with a `player_id` and `session_token`.

## What it does

A 2-player demo match called `demo`:

- 800×600 arena
- 60 second duration
- Players send `{move_x, move_y}` (normalised −1..1) inputs
- Server ticks at 10 Hz (every 100 ms) and broadcasts `match.state` with each player's `{x, y}`
- Match ends after 60 s, server pushes `match.finished`

No combat, no boons, no bots — just enough to exercise the auth → matchmake → match.state → input → match.finished flow across every SDK.

For a richer reference see [asobi_arena_lua](https://github.com/widgrensit/asobi_arena_lua), which implements the full arena shooter (boons, modifiers, bots, voting) on the same runtime.

## Wire protocol

Identical to every Asobi backend — see the [WebSocket protocol guide](https://github.com/widgrensit/asobi/blob/main/guides/websocket-protocol.md).

Relevant events for this demo:

- Client `matchmaker.add` `{mode: "demo"}`
- Server push `match.matched` `{match_id, players}`
- Client `match.input` `{move_x, move_y}` (each is a number in [−1, 1])
- Server push `match.state` `{tick, elapsed_ms, players: {pid: {x, y}}}` every 100 ms
- Server push `match.finished` `{result}` after 60 s

## Layout

```
sdk_demo_backend/
├── docker-compose.yml   # asobi_lua image + Postgres on port 8084
├── lua/
│   ├── config.lua       # game-mode manifest
│   └── match.lua        # the entire demo (~80 lines)
└── README.md
```

## License

Apache-2.0.
