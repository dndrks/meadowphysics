local screen_util = {}

function screen_util.init()
	_seamstress.screen_set(1)
	screen.set_size(137, 73, 5)
	screen.set_position(0,0)

	-- norns-to-seamstress helpers //
	screen.move = function(x, y)
		_seamstress.screen_move(x + 5, y + 5)
	end

	screen.rect = function(x, y, w, h)
		screen.move(x, y)
		screen.rect_fill(w, h)
	end

	screen.line = function(x, y)
		_seamstress.screen_line(x + 5, y + 5)
	end
	-- // norns-to-seamstress helpers

	screen_clk = metro.init()
	screen_clk.event = function()
		if screen_dirty then
			redraw()
			screen_dirty = false
		end
	end
	screen_clk.time = 1 / 60

	-- vars:
	highlight_note = nil
	shift = 0
	shift_focus = "none"
end

function screen.key(char, modifiers, _, state)
	if state == 0 then
		return
	end
	if char.name == "tab" then
		shift = shift ~ 1
		if shift == 0 then
			highlight_note = nil
			shift_focus = "none"
		end
	else
		if shift == 1 then
			if char.name == "left" or char.name == "right" then
				local delta = char.name == "left" and -1 or 1
				if shift_focus == "root" then
					params:delta("root_note", delta)
				elseif shift_focus == "scale" then
					gridscales.selected = util.clamp(gridscales.selected + delta, 1, 16)
				elseif highlight_note ~= nil then
					gridscales.scales[gridscales.selected][highlight_note] =
						util.clamp(gridscales.scales[gridscales.selected][highlight_note] + delta, 0, 7)
				end
			elseif char.name == "up" or char.name == "down" then
				if highlight_note ~= nil then
					local delta = char.name == "up" and 1 or -1
					highlight_note = util.clamp(highlight_note + delta, 1, 8)
				elseif shift_focus == "root" then
					shift_focus = "scale"
				elseif shift_focus == "scale" then
					shift_focus = "root"
				end
			elseif char.name == "escape" then
				highlight_note = nil
				shift_focus = "none"
			end
		end
	end
	grid_dirty = true
	screen_dirty = true
end

local highlight_values = { 7.25, 15.25, 23, 31, 38.75, 47.25, 55.25, 62.75 }
local range = 5.25

local accum = 0
local wheel_accum = 0

local function map_click(x, y)
	for i = 1, 8 do
		for j = 1, 16 do
			local grid_x = ((j - 1) * 8) + 5
			local grid_y = ((i - 1) * 8) + 5
			if x >= grid_x and x < grid_x + 8 and y >= grid_y and y < grid_y + 8 then
				return j, i
			end
		end
	end

	return nil, nil -- click didn't fall within any rect
end

-- when a mouse click occurs:
function screen.click(x, y, state, button)
	if button ~= 1 then
		return
	end
	wheel_accum = 0
	if state == 0 then
		click = nil
		accum = 0
		return
	end
	click = {
		x = x,
		y = y,
	}
	if shift == 1 then
		if x >= 10 and x <= 46 and y >= 52.25 and y <= 59 then
			shift_focus = "root"
			highlight_note = nil
		elseif x >= 10 and x <= 46 and y >= 63.25 and y <= 68.5 then
			highlight_note = nil
			shift_focus = "scale"
		elseif x <= 60.5 or x >= 95 then
			shift_focus = "none"
			highlight_note = nil
			goto process
		elseif y <= highlight_values[1] or y >= highlight_values[#highlight_values] + range then
			highlight_note = nil
			shift_focus = "none"
			goto process
		else
			for i, value in ipairs(highlight_values) do
				if y >= value and y <= value + range then
					highlight_note = 9 - i
					shift_focus = "notes"
					goto process -- exit the loop when a match is found
				end
			end
		end
	else
		local x, y = map_click(x, y)
		if x > 1 then
			mp.position[y] = x
			mp.count[y] = x
			mp.min[y] = x
			mp.max[y] = x
			mp.tick[y] = mp.speed[y]
		end
	end
	::process::
	grid_dirty = true
	screen_dirty = true
end

function screen.wheel(x, y)
	if shift == 1 then
		wheel_accum = wheel_accum + y
		while wheel_accum >= 2 do
			-- delta = + 1
			if shift_focus == "root" then
				params:delta("root_note", 1)
			elseif shift_focus == "scale" then
				gridscales.selected = util.clamp(gridscales.selected + 1, 1, 16)
			elseif highlight_note ~= nil then
				gridscales.scales[gridscales.selected][highlight_note] =
					util.clamp(gridscales.scales[gridscales.selected][highlight_note] + 1, 0, 7)
			end
			wheel_accum = wheel_accum - 2
		end
		while wheel_accum <= -2 do
			if shift_focus == "root" then
				params:delta("root_note", -1)
			elseif shift_focus == "scale" then
				gridscales.selected = util.clamp(gridscales.selected - 1, 1, 16)
			elseif highlight_note ~= nil then
				gridscales.scales[gridscales.selected][highlight_note] =
					util.clamp(gridscales.scales[gridscales.selected][highlight_note] - 1, 0, 7)
			end
			wheel_accum = wheel_accum + 2
		end
	end
	grid_dirty = true
	screen_dirty = true
end

function redraw()
	screen.clear()
	if shift == 1 then
		draw_gridscales()
	else
		draw_mp()
	end
	screen.update()
end

function draw_gridscales()
	screen.level(15)

	screen.move(5, 57)
	screen.color(255, shift_focus == "scale" and 100 or 255, 255)
	screen.text("scale: " .. gridscales.selected)
	screen.move(5, 47)
	screen.color(255, shift_focus == "root" and 100 or 255, 255)
	screen.text("root: " .. gridscales.NOTE_NAMES[root_note])

	for i = 1, 8 do
		screen.color(255, highlight_note == i and 100 or 255, 255)
		screen.move(70, 65 - (i * 8))
		local n = util.clamp(root_note + gridscales:note(i), 0, 127)
		screen.text_right(i .. ": ")
		screen.move_rel(5, 0)
		screen.text(gridscales.NOTE_NAMES[n])
	end
end

function draw_mp()
	for i = 1, 8 do
		for j = mp.min[i], mp.max[i] do
			local y = (i - 1) * 8
			screen.level(3)
			screen.rect((j - 1) * 8, y, 8, 8)
		end
		local y = (i - 1) * 8
		local x = 0
		screen.level(7)
		screen.rect((mp.count[i] - 1) * 8, y, 8, 8)

		if mp.position[i] > 0 then
			x = (mp.position[i] - 1) * 8
			screen.level(15)
			screen.rect(x, y, 8, 8)
		end
	end

	screen.level(4)
	for i = 0, 8 do
		local y = i * 8
		screen.move(0, y)
		screen.line(128, y)
	end

	for i = 0, 16 do
		local x = i * 8
		screen.move(x, 0)
		screen.line(x, 64)
	end
end

return screen_util
