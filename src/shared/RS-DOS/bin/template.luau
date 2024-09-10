local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RSDOS = ReplicatedStorage['RS-DOS']
local CommandBuilder = require(script.Parent.builder)

local result = require(RSDOS.result)

return CommandBuilder.create({
	name = 'template',
	aliases = {'boom', 'bam'},
	description = "test"
}, {
	CommandBuilder.argument('path', "The directory you want to move to")
}, function(elevated, args, io, pane)
	return result.ok(true)
end)