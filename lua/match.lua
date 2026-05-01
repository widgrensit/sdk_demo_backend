-- Minimal SDK demo match.
-- Two players move around an 800x600 arena for 60 seconds. No combat,
-- no boons, no bots — just enough to exercise auth -> matchmake ->
-- match.state -> input -> match.finished across every SDK.

match_size = 2
max_players = 2
strategy = "fill"

local ARENA_W = 800
local ARENA_H = 600
local DURATION_MS = 60000
local TICK_MS = 100
local SPEED = 4

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function init(_config)
    return {
        arena_w = ARENA_W,
        arena_h = ARENA_H,
        players = {},
        elapsed_ms = 0,
        phase = "playing",
        _finished = false
    }
end

function join(player_id, state)
    state.players[player_id] = {
        x = math.random(ARENA_W - 100) + 50,
        y = math.random(ARENA_H - 100) + 50,
        move_x = 0,
        move_y = 0
    }
    return state
end

function leave(player_id, state)
    state.players[player_id] = nil
    return state
end

function handle_input(player_id, input, state)
    if state.phase ~= "playing" then return state end
    local p = state.players[player_id]
    if not p then return state end

    -- Inputs are normalised in [-1, 1].
    p.move_x = clamp(input.move_x or 0, -1, 1)
    p.move_y = clamp(input.move_y or 0, -1, 1)
    return state
end

function tick(state)
    if state.phase ~= "playing" then return state end

    state.elapsed_ms = state.elapsed_ms + TICK_MS

    for _, p in pairs(state.players) do
        p.x = clamp(p.x + p.move_x * SPEED, 0, ARENA_W)
        p.y = clamp(p.y + p.move_y * SPEED, 0, ARENA_H)
    end

    if state.elapsed_ms >= DURATION_MS then
        state.phase = "finished"
        state._finished = true
        state._result = {
            duration_ms = state.elapsed_ms,
            players = state.players
        }
    end

    return state
end

function get_state(_player_id, state)
    return state
end
