local RSDOS = script:FindFirstAncestor("RS-DOS")
local CommandBuilder = require(script:FindFirstAncestor("bin").builder)

local result = require(RSDOS.result)
local utility = require(RSDOS.utility)
local types = require(RSDOS.types)

local bin = nil-- = require(script.Parent)

type sortedCommand = {
	key: string,
	value: types.Command
}

return CommandBuilder.create({
	name = 'help',
	description = "Prints all valid commands and aliases"
}, {}, function(elevated, args, io, pane)
	if not bin then
		bin = require(script:FindFirstAncestor("bin"))
	end

	io:write(`Valid commands:`)

	local commands = utility.toArray(bin.get(), function(a: sortedCommand, b: sortedCommand)
		return b.value.name > a.value.name
	end) :: {sortedCommand}

	for _, command in ipairs(commands) do
		local c = command.value

		local aliases = if #c.aliases > 0 then table.concat(c.aliases, ", ") else nil
		local desc = if c.description then c.description else "No description"

		io:write(`  {c.name}{if aliases then ` ({aliases})` else ""} - {desc}`)
	end
	
	return result.ok(true)
end)