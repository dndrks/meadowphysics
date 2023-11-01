-- grid interactions
local mp_grid = {}

g = grid.connect()

function mp_grid.init()
	gridscales = GridScales.loadornew(data_dir .. "gridscales.data")
	gridscales:add_params()
	grid_clk = metro.init()
	grid_clk.event = mp_grid.redraw
	grid_clk.time = 1 / 60
end

function g.key(x, y, z)
	if shift == 1 then
		gridscales:gridevent(x, y, z)
	else
		mp:gridevent(x, y, z)
	end
	grid_dirty = true
	screen_dirty = true
end

function mp_grid.redraw()
	if grid_dirty then
		if shift == 1 then
			gridscales:gridredraw(g)
		else
			mp:gridredraw(g)
		end
		grid_dirty = false
	end
end

function grid.add(dev)
	grid_connected = true
	grid_dirty = true
	mp:gridredraw(dev)
end

return mp_grid
