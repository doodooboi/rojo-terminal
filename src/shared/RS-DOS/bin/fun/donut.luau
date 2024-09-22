local RSDOS = script:FindFirstAncestor("RS-DOS")
local CommandBuilder = require(script:FindFirstAncestor("bin").builder)

local result = require(RSDOS.result)

local sin = math.sin
local cos = math.cos

local chars = { ".", ",", "-", "~", ":", ";", "=", "!", "*", "#", "$", "@" }

-- https://github.com/TheBiggyBoss/SPINNING-DONUT-with-C/blob/main/main.c
return CommandBuilder.create({
	name = "donut",
	description = "test",
}, {}, function(elevated, args, io, pane)
	local interrupted = false
	pane.janitor:Add(
		pane.signals.SIGINT:Once(function()
			interrupted = true
		end),
		"Disconnect"
	)

	io:swap()

	while not interrupted do
		local A, B = 0, 0
		local z = table.create(1761, 0)
		local b = table.create(1761, "")

		for j = 0, 6.28, 0.07 do
			for i = 0, 6.28, 0.02 do
				local c = sin(i)
				local d = cos(j)
				local e = sin(A)
				local f = sin(j)
				local g = cos(A)
				local h = d + 2
				local D = 1 / (c * h * e + f * g + 5)
				local l = cos(i)
				local m = cos(B)
				local n = sin(B)
				local t = c * h * g - f * e

				local x = 40 + 30 * D * (l * h * m - t * n)
				local y = 12 + 15 * D * (l * h * n + t * m)
				local o = (x + 80 * y) // 1
				local N = 8 * ((f * e - c * d * g) * m - c * d * e - f * g - l * d * n)

				if not z[o] then
					warn(z, o )
				end
				if 22 > y and y > 0 and x > 0 and x < 80 and D > z[o] then
					z[o] = D
					b[o] = string.sub(".,-~:;=!*#$@", math.max(N, 0) + 1, math.max(N, 0) + 1)
					-- z[o] = D;;;b[o]= chars[if N > 0 then N else 0];
				end
			end

			io:flush()

			for k = 1, 1761 do
				local out = {}
				if k % 80 == 0 then
					io:write(table.concat(out), k)
				else
					table.insert(out, b[k])
				end
			end
		end
		task.wait()
	end

	return result.ok(true)
end)
