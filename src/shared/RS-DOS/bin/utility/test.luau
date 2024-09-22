local RSDOS = script:FindFirstAncestor("RS-DOS")
local CommandBuilder = require(script:FindFirstAncestor("bin").builder)

local result = require(RSDOS.result)
local utility = require(RSDOS.utility)

local xterm256 = require(RSDOS.components.xterm256)

return CommandBuilder.create({
	name = 'test',
	aliases = {'try'},
	description = "Test features out"
}, {
	CommandBuilder.argument('feature', "The feature to try out")
}, function(elevated, args, io, pane)
	local feature = args[1]
	
	local interrupted = false
	pane.janitor:Add(pane.signals.SIGINT:Once(function()
		interrupted = true
	end), "Disconnect")

	if feature == "defer" then
		io:write("Now deferring updates")
		io:deferUpdates(true)
	
		io:write("Hello, World! [deferred]")
		io:write("Bitalii, Fegyn [deferred]")
		io:write("Resuming updates")
	
		task.wait(0.5)
		
		io:deferUpdates(false, true)
		return result.ok(true)
	elseif feature == 'iomod' then
		local number = 0

		while not interrupted do
			io:deferUpdates(true)
			number += 1
			
			if number % 2 == 0 then
				io:write(`{number} is even!`)
			end 

			io:write(`Counting: {number}`, "count")
			io:write("Progress "..number, "count2")

			io:push("count")
			io:push("count2")

			io:deferUpdates(false)
			task.wait(0)
		end

		return result.ok(nil)
	elseif feature == "err" then
		if utility.getFlag(args[2]) == "s" then
			return result.err(args[3] or "No supplied error")
		end

		error(args[2] or "No supplied error")
	elseif feature == 'progress' then
		local length = tonumber(args[2]) or 15

		for i = 1, length do
			if interrupted then continue end

			local difference = length - i
			local percent = ((i / length) * 100) // 1

			io:write(`-[{xterm256(`{string.rep("■", i)}{string.rep(" ", difference)}`, 2)}]- {percent}%`, "block")

			task.wait(0.1)
		end

		return result.ok(nil)
	elseif feature == "stdin" then
		io:write("Prompting user now")
		local got = io:read(args[2] or "Please provide input:")

		io:write(`{xterm256(`You entered: `, 6)}{got}`)
		return result.ok(nil)
	end

	return result.err(`Invalid feature '{feature}'`)
end)