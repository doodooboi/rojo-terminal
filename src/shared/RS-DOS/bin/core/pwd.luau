local RSDOS = script:FindFirstAncestor("RS-DOS")
local CommandBuilder = require(script:FindFirstAncestor("bin").builder)

local utility = require(RSDOS.utility)
local result = require(RSDOS.result)

return CommandBuilder.create({
	name = 'pwd',
	description = "Output current working directory"
}, {
	CommandBuilder.argument('path', "The directory you want to move to")
}, function(elevated, args, io, pane)
	io:write(utility.stripRichtext(pane.at.pwd))

	return result.ok(true)
end)