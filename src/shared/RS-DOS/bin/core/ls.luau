local RSDOS = script:FindFirstAncestor("RS-DOS")
local CommandBuilder = require(script:FindFirstAncestor("bin").builder)

local utility = require(RSDOS.utility)
local result = require(RSDOS.result)
local types = require(RSDOS.types)
local path = require(RSDOS.path)

local xterm256 = require(RSDOS.components.xterm256)

return CommandBuilder.create({
	name = 'ls',
	aliases = {'dir'},
	description = "List all files and directories"
}, {
	CommandBuilder.argument('path', 'Source directory', true),
}, function(elevated, args, io, pane)

	local str = {}
	local toSearch: types.Directory = pane.at.directory

	if args[1] then
		local returned = path.resolve(args[1], pane.at.directory)

		if returned.type == 'ok' then
			toSearch = returned.value
		else
			return result.err(`cannot access '{args[1]}': {returned.err}`)
		end
	end

	local wrote = 0
	for index, _ in pairs(toSearch.contents) do
		local isDir = utility.whatIs(index) == 'directory'

		if isDir then
			table.insert(str, xterm256(`{index:sub(2, -1)}\t`, 39))
		else
			table.insert(str, `{index}\t`)
		end

		wrote += 1
	end

	if wrote > 0 then
		io:write(table.concat(str))
	end
	
	return result.ok(true)
end)