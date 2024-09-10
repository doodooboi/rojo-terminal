local RSDOS = script.Parent.Parent
local CommandBuilder = require(script.Parent.builder)

local result = require(RSDOS.result)
local path = require(RSDOS.path)

return CommandBuilder.create({
	name = 'cat',
	description = "Read file contents"
}, {
	CommandBuilder.argument('file', 'The file to read')
}, function(elevated, args, io, pane)
	if not args[1] then return end

	local returned = path.resolve(args[1], pane.at.directory)
	if returned.type == 'err' then
		return result.err(`{args[1]}: {returned.err}`)
	end

	if returned.value.class == 'directory' then
		return result.err(`{args[1]}: Is a directory`)
	end

	io:write(returned.value.contents)

	return result.ok(true)
end)