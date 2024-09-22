local RSDOS = script:FindFirstAncestor("RS-DOS")
local CommandBuilder = require(script:FindFirstAncestor("bin").builder)

local result = require(RSDOS.result)

return CommandBuilder.create({
	name = 'cls',
	aliases = {'clear'},
	description = "Clear terminal output"
}, {}, function(_, _, io)
	io:flush(true)
	
	return result.ok(true)
end)