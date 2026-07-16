-- Second demo mode: same movement loop as match.lua, but a 4-player
-- party in a larger arena. It exists to show that config.lua maps
-- several modes to several scripts, and that each script sets its own
-- config (match_size, arena size, duration) via globals.

match_size = 4
max_players = 4
strategy = "fill"

local ARENA_W = 1200
local ARENA_H = 900
local DURATION_MS = 90000
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
