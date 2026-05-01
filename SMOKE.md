# SDK Smoke Test Specification

This document defines the canonical smoke test every Asobi SDK must pass against `sdk_demo_backend`. Every release of every SDK is gated on this test passing.

## Why this exists

SDKs analyze cleanly all the time and still ship broken. The only thing that proves a client SDK is *actually* talking to an Asobi backend is running the canonical flow end-to-end against a known-good server. `sdk_demo_backend` is that known-good server.

## Backend bring-up

Every smoke test assumes a `sdk_demo_backend` instance is running locally:

```bash
git clone https://github.com/widgrensit/sdk_demo_backend
cd sdk_demo_backend && docker compose up -d
```

The backend listens on `http://localhost:8084` (HTTP + WebSocket on `/ws`) with a 2-player `demo` mode (60-second movement-only round, 10 Hz tick rate).

The smoke test should accept an `ASOBI_URL` environment variable and default to `http://localhost:8084` when unset.

## Canonical flow

The smoke test implements **one** flow with three observable scenarios. Total expected runtime: under 10 seconds.

### Scenario 1 — auth + WebSocket connect

For two distinct players (`A` and `B`):

1. `POST /api/v1/auth/register` with a unique username, password `smoke_pw_12345`, and the username as display name. Expect `201` (or `200`) with a session token.
2. Open a WebSocket to `/ws` with the session token (header / query / first-message — whichever the SDK supports).
3. Receive the SDK's "connected" / "session.welcome" / equivalent ready signal.

Expected outcome: both clients have a `player_id` and a connected WebSocket.

### Scenario 2 — matchmaker → `match.matched`

1. **Register the `match.matched` listener on both clients before queueing.** The listener must be in place before the first `matchmaker.add` call to avoid a race.
2. Both clients send `matchmaker.add` with mode `"demo"`.
3. Within **10 seconds** both clients must receive a `match.matched` event with **the same** `match_id`.

> ⚠️ Two events look similar but mean different things:
>
> - `match.matched` — server-pushed when the matchmaker pairs you. **This is what the smoke listens for.**
> - `match.joined` — reply to a client-initiated `match.join` message (not used here).
>
> If your SDK exposes a single `OnMatchReady` / `onMatched` API that fires for both, that's fine; document it.

Expected outcome: shared `match_id` confirmed across both clients.

### Scenario 3 — `match.input` → `match.state` with input applied

1. Player A subscribes to `match.state`.
2. Read the **first** `match.state` and capture `players[A.player_id].x` as `x_initial`. Player spawn `x` is random in `[50, 700]`, so an `x >= 1` check trivially passes — the smoke must compare against `x_initial`, not a literal.
3. Player A sends one `match.input` payload: `{move_x: 1, move_y: 0}`.
4. Within **3 seconds**, Player A must observe a subsequent `match.state` where `players[A.player_id].x > x_initial + 10`.

> The match script ticks at 10 Hz with `SPEED=4` px/tick. After 1 second of `move_x=1` the player's `x` should have advanced by ~40. The `+10` threshold gives generous slack for transit / first-state-received delay.

Expected outcome: the input made it through, the server applied it, and the resulting state reached the client.

## Cleanup

Both clients disconnect cleanly. The test process exits with status `0` on success, non-zero on any failure or timeout.

## Implementation requirements

Every SDK's smoke test must:

- [x] Live at `smoke_tests/` (or the SDK's idiomatic equivalent — `tests/Runtime/` for Unity, `Source/AsobiSDK/Tests/` for Unreal, etc.).
- [x] Default to `http://localhost:8084` and read `ASOBI_URL` env var to override.
- [x] Use mode `"demo"` (not `"smoke"`, `"arena"`, or any other).
- [x] Use unique random usernames per run (e.g. `smoke_a_<timestamp>_<rand>`) to avoid collisions across reruns.
- [x] Wait for the backend to be reachable before starting (poll `POST /api/v1/auth/register` until response `< 500`, up to 60 s) — `docker compose up` takes a few seconds to become live.
- [x] Log progress with a `[smoke]` prefix line per scenario.
- [x] Exit non-zero on any timeout or assertion failure.

## CI integration

Each SDK's CI must:

1. Check out the SDK repo.
2. Clone `widgrensit/sdk_demo_backend`.
3. Run `docker compose up -d` in `sdk_demo_backend/`.
4. Wait for the backend (the smoke's own `wait_for_server` covers this, but a `curl` precheck makes failures clearer).
5. Run the smoke test.
6. On failure, dump `docker compose logs` for debugging.
7. Tear down with `docker compose down -v`.

A reference workflow snippet (GitHub Actions):

```yaml
- name: Bring up sdk_demo_backend
  run: |
    git clone https://github.com/widgrensit/sdk_demo_backend
    cd sdk_demo_backend && docker compose up -d

- name: Run smoke
  env:
    ASOBI_URL: http://localhost:8084
  run: <SDK-specific smoke command>

- name: Backend logs on failure
  if: failure()
  run: cd sdk_demo_backend && docker compose logs
```

## DX agent integration

Every `asobi-dx-*` agent's pre-release pass must include running this smoke test against a fresh `docker compose up` of `sdk_demo_backend`. A successful smoke is a release-blocker; a doc-friction report is informational. Agents should report the smoke result first.

## Checklist for new SDKs

When adding a new SDK (LÖVE, Phaser, etc.):

- [ ] Implement the canonical flow above in the SDK's idioms.
- [ ] Wire it into CI per the reference workflow.
- [ ] Update the SDK's README quickstart to point at `sdk_demo_backend` mode `"demo"` on `:8084`.
- [ ] Create a paired `asobi-dx-<sdk>` agent definition that mentions running this smoke.
- [ ] Add a row to the SDK matrix in the asobi project README / docs.
