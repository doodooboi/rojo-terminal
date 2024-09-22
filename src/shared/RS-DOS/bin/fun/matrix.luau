local RSDOS = script:FindFirstAncestor("RS-DOS")
local CommandBuilder = require(script:FindFirstAncestor("bin").builder)

local result = require(RSDOS.result)
local xterm256 = require(RSDOS.components.xterm256)

local noise = math.noise

return CommandBuilder.create({
	name = 'matrix',
	description = "Cool",
}, {}, function(elevated, args, io, pane)
	local interrupted = false
	pane.janitor:Add(pane.signals.SIGINT:Once(function()
		interrupted = true

		io:write("SIGINT handled.")
	end), "Disconnect")

	io:swap()
	local offsetX = 0
	local offsetY = 0

	local seed = os.time()
	local char = '0'

	while not interrupted do
		io:deferUpdates(true)

		for y = 1, pane.max_y do
			local str = {}
			for x = 1, pane.max_x do
				local height = noise(seed, (x + offsetX) / 0.312, (y + offsetY) / 5.25) * 12

				table.insert(str, xterm256(char, (height // 1) % 255))
			end

			offsetX += 1.632
			io:write(table.concat(str), tostring(y))
		end

		task.wait()

		io:deferUpdates(false)
		offsetY += 2.46
	end

	return result.ok(true)
end)