local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RSDOS = ReplicatedStorage['RS-DOS']
local CommandBuilder = require(script.Parent.builder)

local result = require(RSDOS.result)
local fs = require(RSDOS.fs)

return CommandBuilder.create({
	name = 'mkdir',
	description = "Unimplemented: Create directory"
}, {
	CommandBuilder.argument('path', "The path/name of the directory to make")
}, function(elevated, args, io, pane)
	print(args)

	return result.ok(true)
end)