-- Single-player game.send round-trip demo mode. Player queues alone
-- (match_size = 1), sends match.input {message = ...}, and handle_input
-- echoes it straight back via game.send with a running per-player input
-- counter — so SDKs have a real server to assert game.send delivery
-- against (the regression class behind widgrensit/asobi#235).
--
-- Sending {message = "boom"} deliberately raises a Lua runtime error
-- inside handle_input, so SDKs can also assert the server's game.error
-- dispatch end to end (requires ASOBI_DEV_ERRORS=true — see
-- docker-compose.yml — otherwise the error is log-only and never
-- reaches the client).

match_size = 1
max_players = 1
strategy = "fill"

function init(_config)
    return { counts = {} }
end

function join(player_id, state)
    state.counts[player_id] = 0
    return state
end

function leave(player_id, state)
    state.counts[player_id] = nil
    return state
end

function handle_input(player_id, input, state)
    if input.message == "boom" then
        local n = nil
        return n + 1 -- deliberate runtime error -> game.error
    end

    local count = (state.counts[player_id] or 0) + 1
    state.counts[player_id] = count
    game.send(player_id, {echo = input.message, count = count})
    return state
end

function tick(state)
    return state
end

function get_state(_player_id, state)
    return state
end
