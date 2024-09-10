local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RSDOS = ReplicatedStorage['RS-DOS']
local CommandBuilder = require(script.Parent.builder)

local result = require(RSDOS.result)

return CommandBuilder.create({
	name = 'echo',
	description = "Simply outputs input"
}, {}, function(elevated, args, io, pane)
	io:write(args[1])
	
	return result.ok(true)
end)