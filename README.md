# SDK Demo Backend

Tiny Lua game running on the [asobi_lua](https://github.com/widgrensit/asobi_lua) Docker image. This is the canonical backend the [Asobi SDK demos](https://github.com/widgrensit/asobi#sdks) point at.

It exists so SDK quickstarts have one command (`docker compose up -d`) instead of "install Erlang, install rebar3, run migrations, then run an Erlang shell."

## Quick Start

```bash
git clone https://github.com/widgrensit/sdk_demo_backend.git
cd sdk_demo_backend
docker compose up -d
```

The backend listens on `http://localhost:8084` (HTTP + WebSocket on `/ws`).

Verify by registering a throwaway player:

```bash
curl -X POST http://localhost:8084/api/v1/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"username":"smoke","password":"smoke1234","display_name":"Smoke"}'
```

You should get a `200` with a `player_id`, `access_token`, and `refresh_token`. Clients send the `access_token` as a Bearer token (and on the WebSocket `session.connect`); when it expires, `POST /api/v1/auth/refresh` with the `refresh_token` returns a fresh pair.

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
