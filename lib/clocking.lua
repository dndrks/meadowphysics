-- this is a system callback, which executes whenever
--   seamstress's clock receives a 'transport start' message
function clock.transport.start()
	params:set("transport_control", 0) -- stop our sequencer
	params:set("transport_control", 1, true) -- flip transport UI in params
	-- ^ 'true' at the end means 'silent', which doesn't trigger the action
	transport("start") -- start our sequencer
end

-- this is a system callback, which executes whenever
--   seamstress's clock receives a 'transport stop' message
function clock.transport.stop()
	params:set("transport_control", 0) -- stop our sequencer
end

-- here, we define what a 'start' and 'stop' mean for this script:
function transport(action)
	if action == "start" then
		mp_clock = clock.run(play)
	elseif action == "stop" then
		stop()
		if mp_clock ~= nil then
			clock.cancel(mp_clock)
		end
		-- reset play position:
		mp:reset_all_steps()
	end
	-- redraw interfaces:
	grid_dirty = true
	screen_dirty = true
end
