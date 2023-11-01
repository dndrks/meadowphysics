-- meadowphysics
-- adapted for seamstress by @dndrks
--   from https://github.com/alpha-cactus/meadowphysics
--   and https://github.com/monome/monome-max-package/blob/main/javascript/mp.js

MeadowPhysics = include("meadowphysics/lib/meadowphysics")
GridScales = include("meadowphysics/lib/gridscales")
mu = require("musicutil")
mp_grid = include("lib/grid")
mp_screen = include("lib/screen")
include("lib/clocking")

-- useful for storing custom files alongside PSETs:
data_dir = path.seamstress .. "/data/" .. seamstress.state.name .. "/"

local options = {}
options.STEP_LENGTH_NAMES =
	{ "1 bar", "1/2", "1/3", "1/4", "1/6", "1/8", "1/12", "1/16", "1/24", "1/32", "1/48", "1/64" }
options.STEP_LENGTH_DIVIDERS = { 1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64 }

notes = {}
active_notes = {}
toggle_notes = {}

local function all_notes_off()
	for _, a in pairs(active_notes) do
		midi_devices[a.dev]:note_off(a.note, nil, midi_out_channel)
	end
	active_notes = {}
end

notes_off_metro = metro.init()
notes_off_metro.event = all_notes_off

function init()
	midi_devices = {} -- build a table of connected MIDI devices for MIDI input + output
	midi_device_names = {} -- index their names to display them in params
	for i = 1, #midi.vports do -- for each MIDI port:
		midi_devices[i] = midi.connect(i) -- connect to the device
		midi_device_names[i] = i .. ": " .. midi.vports[i].name -- log its name
	end

	params:add_separator("meadowphysics_title", "meadowphysics")

	params:add_binary(
		"transport_control", -- ID
		"start/stop", -- display name
		"toggle", -- type
		0 -- default
	)

	params:set_action("transport_control", function(x)
		if x == 1 then
			if params:string("clock_source") == "internal" then
				clock.internal.start()
			else
				transport("start")
			end
			for i = 1, 8 do
				if mp.toggle[i] > 0 then
					mp.state[i] = 1
				end
			end
		else
			transport("stop")
		end
	end)

	-- we want the transport to be independent of the PSET save/restore:
	params:set_save("transport_control", false)

	params:add({
		type = "option",
		id = "step_length",
		name = "step length",
		options = options.STEP_LENGTH_NAMES,
		default = 8,
		action = function(value)
			step_length = value
			steps_per_beat = options.STEP_LENGTH_DIVIDERS[value] / 4
		end,
	})

	params:add({
		type = "option",
		id = "note_length",
		name = "note length",
		options = { "25%", "50%", "75%", "100%" },
		default = 4,
		action = function(value)
			note_length = value
		end,
	})

	params:add_separator("MIDI output")
	params:add({
		type = "option",
		id = "midi_out_device",
		name = "port",
		options = midi_device_names,
		default = 1,
		action = function(value)
			midi_out_device = value
		end,
	})

	params:add({
		type = "number",
		id = "midi_out_channel",
		name = "midi out channel",
		min = 1,
		max = 16,
		default = 1,
		action = function(value)
			all_notes_off()
			midi_out_channel = value
		end,
	})

	-- meadowphysics
	mp = MeadowPhysics.loadornew(data_dir .. "mp.data")
	mp.mp_event = event

	mp_grid.init()
	mp_screen.init()

	params:bang()

	screen_clk:start()
	grid_clk:start()
end

function step()
	all_notes_off()

	mp:clock()

	for _, n in pairs(notes) do
		local note = n.note
		local row = n.row
		local f = mu.note_num_to_freq(note)
		midi_devices[midi_out_device]:note_on(note, 96, midi_out_channel)
		table.insert(active_notes, { dev = midi_out_device, note = note })
	end
	notes = {}

	if note_length < 4 then
		notes_off_metro:start((60 / clock.get_tempo() / steps_per_beat / 4) * note_length, 1)
	end
end

function toggle_step(i, state)
	if state == true and mp.toggle_steps[i] == false then
		mp.toggle_steps[i] = true
		midi_devices[midi_out_device]:note_on(toggle_notes[i], 96, midi_out_channel)
	elseif state == false and mp.toggle_steps[i] == true then
		mp.toggle_steps[i] = false
		midi_devices[midi_out_device]:note_off(toggle_notes[i], nil, midi_out_channel)
	end
end

function event(row, i, state)
	if state == 1 then
		if mp.toggle[i] > 0 and mp.position[i] == 1 then
			toggle_notes[i] = root_note + gridscales:note(row)
			toggle_step(i, true)
		elseif mp.toggle[i] == 0 then
			table.insert(notes, { note = root_note + gridscales:note(row), row = row })
		end
	elseif state == 0 then
		if mp.toggle[i] > 0 and mp.position[i] == 1 then
			toggle_step(i, false)
		end
	end
end

function play()
	while true do
		step()
		clock.sync((1 / options.STEP_LENGTH_DIVIDERS[step_length]) * 4)
	end
end

function stop()
	all_notes_off()
	for i = 1, 8 do
		if toggle_notes[i] ~= nil then
			midi_devices[midi_out_device]:note_off(toggle_notes[i], nil, midi_out_channel)
		end
	end
end

params.action_write = function(filename, name, number)
	local filepath = data_dir .. number .. "/"
	util.make_dir(filepath)
	mp:save(filepath .. "mp.data")
	gridscales:save(data_dir .. "gridscales.data")
end

params.action_read = function(filename, name, number, silent)
	local filepath = data_dir .. number .. "/"
	mp = MeadowPhysics.loadornew(filepath .. "mp.data")
	mp.mp_event = event
	mp:reset_all_steps()
	gridscales = GridScales.loadornew(data_dir .. "gridscales.data")
	grid_dirty = true
	screen_dirty = true
end

function cleanup()
	all_notes_off()
	g:all(0)
	g:refresh()
end
