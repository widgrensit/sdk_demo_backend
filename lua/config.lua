-- Game-mode manifest: maps a mode name to the match script that runs it.
-- The client picks a mode with matchmaker.add {mode = "demo"}.
-- Each script sets its own config (match_size, arena, duration) via globals.
return {
    demo = "match.lua",
    party = "party.lua"
}
