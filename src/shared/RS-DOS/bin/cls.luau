local RSDOS = script.Parent.Parent
local CommandBuilder = require(script.Parent.builder)

local result = require(RSDOS.result)

return CommandBuilder.create({
	name = 'cls',
	aliases = {'clear'},
	description = "Clear terminal output"
}, {}, function(_, _, io)
	io:flush(true)
	
	return result.ok(true)
end)