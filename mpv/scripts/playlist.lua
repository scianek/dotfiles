local config = {
    keybindings = {
        show_playlist = "p",
        hide_playlist = "ESC",
        moveup = "UP",
        movedown = "DOWN",
        pageup = "KP9",
        pagedown = "KP3",
        play = "ENTER",
    },
    icons = {
        normal = "○ ",
        hovered = "● ",
        playing = "▷ ",
        playing_hovered = "▶ ",
    },
    ass_styles = {
        normal = "{\\fs70\\fnSF Pro Display}",
    },
    entries_on_screen = 20,
}

local mp = require("mp")
local msg = require("mp.msg")
local assdraw = require("mp.assdraw")

local playlist
local playlist_visible = false
local hovered_idx = 1
local duration_cache = {}
local keybindings = {
    {
        config.keybindings.moveup,
        "moveup",
        function()
            playlist_move(-1)
        end,
        { repeatable = true },
    },
    {
        config.keybindings.movedown,
        "movedown",
        function()
            playlist_move(1)
        end,
        { repeatable = true },
    },
    {
        config.keybindings.pagedown,
        "pagedown",
        function()
            playlist_move(config.entries_on_screen)
        end,
        { repeatable = true },
    },
    {
        config.keybindings.pageup,
        "pageup",
        function()
            playlist_move(-1 * config.entries_on_screen)
        end,
        { repeatable = true },
    },
    {
        config.keybindings.play,
        "play",
        function()
            mp.commandv("playlist-play-index", hovered_idx - 1)
            hide_playlist()
        end,
    },
    { config.keybindings.hide_playlist, "hide_playlist", hide_playlist },
}

function parse_raw_playlist(raw_playlist)
    local playlist_entries = {}
    for path in raw_playlist:gmatch('{"filename":"(.-)"') do
        table.insert(playlist_entries, path)
    end
    return playlist_entries
end

--TODO: handle incompatible filetypes
function get_video_duration(path)
    if duration_cache[path] == nil then
        local handle = io.popen(
            'ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "' .. path .. '"'
        )

        if handle ~= nil then
            local duration_raw = handle:read("*a")
            local duration_in_secs = duration_raw:match("^(.-)%..+$")
            local minutes = math.floor(duration_in_secs / 60)
            local seconds = duration_in_secs - minutes * 60
            local duration = minutes .. ":" .. (seconds >= 10 and seconds or "0" .. seconds)
            duration_cache[path] = duration
            handle:close()
        else
            msg.warn("Couldn't retrieve the file information. Make sure ffmpeg is available.")
        end
    end

    return duration_cache[path]
end

function toggle_playlist_visibility()
    if playlist_visible then
        hide_playlist()
    else
        show_playlist()
    end
end

function show_playlist()
    playlist_visible = true
    for _, kb in pairs(keybindings) do
        mp.add_key_binding(kb[1], kb[2], kb[3], kb[4])
        -- mp.add_key_binding(table.unpack(kb))
    end
    render_playlist()
end

function hide_playlist()
    playlist_visible = false
    for _, kb in pairs(keybindings) do
        mp.remove_key_binding(kb[2])
    end
    local w, h = mp.get_osd_size()
    mp.set_osd_ass(w, h, "")
end

function calculate_display_bounds(limit, len)
    if len <= limit then
        return 1, len
    end

    local start
    if hovered_idx - (limit / 2) < 1 then
        start = 1
    elseif hovered_idx + (limit / 2) > len then
        start = len - limit + 1
    else
        start = hovered_idx - (limit / 2)
    end

    return start, math.min(start + limit - 1, len)
end

function render_playlist()
    local ass = assdraw.ass_new()
    ass:draw_start()
    ass:new_event()
    ass:append(config.ass_styles.normal .. "[" .. hovered_idx .. "/" .. #playlist .. "]")

    local first, last = calculate_display_bounds(config.entries_on_screen, #playlist)
    for i = first, last do
        if i > #playlist then
            break
        end
        ass:new_event()

        local icon
        local playing_idx = tonumber(mp.get_property("playlist-current-pos")) + 1
        if i == hovered_idx and i == playing_idx then
            icon = config.icons.playing_hovered
        elseif i == playing_idx then
            icon = config.icons.playing
        elseif i == hovered_idx then
            icon = config.icons.hovered
        else
            icon = config.icons.normal
        end

        local path = playlist[i]
        local _, _, title = path:find("^.+/(.+)$")
        --TODO: display duration for each video
        -- local duration = '[' .. get_video_duration(path) .. ']'
        ass:append(config.ass_styles.normal .. icon .. title)
    end

    ass:draw_stop()
    local w, h = mp.get_osd_size()
    mp.set_osd_ass(w, h, ass.text)
end

function playlist_move(step)
    hovered_idx = (hovered_idx + step) % #playlist
    if hovered_idx == 0 then
        hovered_idx = #playlist
    end
    render_playlist()
end

function handle_start()
    playlist = parse_raw_playlist(mp.get_property("playlist"))
    mp.add_key_binding(config.keybindings.show_playlist, "toggle", function()
        toggle_playlist_visibility()
    end)

    mp.osd_message(mp.get_property("filename"), 3)
end

mp.register_event("start-file", handle_start)
