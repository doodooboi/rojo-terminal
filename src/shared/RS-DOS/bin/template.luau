local RSDOS = script:FindFirstAncestor("RS-DOS")
local CommandBuilder = require(script:FindFirstAncestor("bin").builder)

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