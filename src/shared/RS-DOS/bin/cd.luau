local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RSDOS = ReplicatedStorage['RS-DOS']
local CommandBuilder = require(script.Parent.builder)

local result = require(RSDOS.result)
local path = require(RSDOS.path)

return CommandBuilder.create({
	name = 'cd',
	description = "Navigate through directories"
}, {
	CommandBuilder.argument('path', "The directory you want to move to")
}, function(elevated, args, io, pane)
	if not args[1] then return end
	
	local returned = path.resolve(args[1], pane.at.directory)
	if returned.type == 'err' then
		return result.err(`{args[1]}: {returned.err}`)
	end

	if returned.value.class == 'file' then
		return result.err(`{args[1]}: Not a directory`)
	end

	pane.at.directory = returned.value

	return result.ok(true)
end)