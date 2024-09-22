local RSDOS = script.Parent

local types = require(RSDOS.types)
local result = require(RSDOS.result)
local utility = require(RSDOS.utility)

local xterm256 = require(RSDOS.components.xterm256)

-- curse you typechecking
local setmetatable = setmetatable

local aliases = {} :: types.Map<string, types.Command>
local errors = {} :: {string}

local seen = {"builder", "template"}

local commands: types.Map<string, types.Command> = {}; do
	for _, child: ModuleScript in ipairs(script:GetDescendants()) do
		if not child:IsA("ModuleScript") or table.find(seen, child.Name) then continue end
		table.insert(seen, child.Name)

		local success, command: types.Command = xpcall(require, function(err)
			table.insert(errors, child.Name)
		end, child)

		if not success then continue end

		command.aliases = command.aliases or {}
		commands[command.name] = command
		for _, alias in ipairs(command.aliases) do
			aliases[alias] = command
		end
	end
end

local bin = {
	get = function()
		return commands
	end,
	errors = function()
		return errors
	end
}

local meta = {
	__call = function(_,
		 input: string, 
		 elevated: boolean, 
		 pane: types.pane
	)
			local split = utility.splitSpacePreserveQuotes(input)
			local saidCommand = table.remove(split, 1)

			local command = commands[saidCommand] or aliases[saidCommand]
			if not command then
				pane.signals.processed:Fire(result.err(`Command '{saidCommand}' not found`))
				return
			end

			local thread = task.spawn(function()
				local success, returned = pcall(command.callback, elevated, split, pane.IOManager, pane)
				if not success then
					pane.signals.processed:Fire(result.ok(
						result.err(xterm256(`Encountered script error: {returned}`, 9))
					))
				else
					pane.signals.processed:Fire(result.ok(
						returned or result.ok(nil)
					))
				end
				
				pane.running = nil
			end)

			pane.running = thread
	end,
}

return setmetatable(bin, meta)