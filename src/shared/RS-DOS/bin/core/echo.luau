local RSDOS = script:FindFirstAncestor("RS-DOS")
local CommandBuilder = require(script:FindFirstAncestor("bin").builder)

local result = require(RSDOS.result)

return CommandBuilder.create({
	name = 'echo',
	description = "Simply outputs input"
}, {}, function(elevated, args, io, pane)
	io:write(args[1])
	
	return result.ok(true)
end)