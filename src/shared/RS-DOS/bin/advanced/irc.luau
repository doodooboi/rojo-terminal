local _ReplicatedStorage = game:GetService("ReplicatedStorage")

local RSDOS = script:FindFirstAncestor("RS-DOS")
local CommandBuilder = require(script:FindFirstAncestor("bin").builder)

local result = require(RSDOS.result)

return CommandBuilder.create({
	name = 'irc',

	description = "Connect to a IRC channel"
}, {}, function(elevated, args, io, pane)
	return result.ok(true)
end)