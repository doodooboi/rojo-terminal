--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RSDOS = ReplicatedStorage['RS-DOS']
local CommandBuilder = require(script.Parent.builder)

local result = require(RSDOS.result)
local utility = require(RSDOS.utility)
local path = require(RSDOS.path)

local xterm256 = require(RSDOS.components.xterm256)

local featureSet = {
	["fs"] = {
		"arguments:",
		"  path - Directory to output"
	},

	["io"] = {
		"flags:",
		"  count - Output buffer size",
		"  dump - Output full buffer and memory to console (F9)",
		"  flush - Flush buffer and memory",
		"  holes - Output reserved holes"
	},
}

return CommandBuilder.create({
	name = 'debug',
	description = "Debug various features"
}, {}, function(elevated, args, io, pane)
	local interrupted = false
	pane.janitor:Add(pane.signals.SIGINT:Once(function()
		interrupted = true
	end), "Disconnect")

	local feature = args[1]
	local flag = utility.getFlag(args[2])

	local failedFlag = true

	if feature == "io" then
		if flag == "dump" then
			failedFlag = false
			print(io.buffer, io.memory)
		elseif flag == "flush" then
			failedFlag = false
			io:flush(true)
		elseif flag == 'count' then
			failedFlag = false
			io:write(tostring(io:size()))
		elseif flag == 'holes' then
			failedFlag = false
			local buf = io.buffer
			local holes = 0

			for i = 1, io:size() do
				if not buf[i] then
					holes += 1		
				end
			end

			io:write(`{holes}`)
		end
	elseif feature == 'fs' and args[2] then
		failedFlag = false
		local lookup = path.resolve(args[2], pane.at.directory)
		if lookup.type == 'err' then
			return result.err(lookup.err)
		end

		local split = utility.tableToString(lookup.value):split("\n")
		io:deferUpdates(true)

		for _, line in ipairs(split) do
			io:write(line)
		end

		io:deferUpdates(false)

		return result.ok(nil)
	end

	local failed = false

	if not feature then
		io:write(`No feature provided`)
		failed = true
	elseif failedFlag then
		io:write(`Invalid flag/argument for {feature}: '{flag}'`)
		failed = true
	elseif not featureSet[feature] then
		io:write(`Invalid feature {feature}`)
		failed = true
	end

	if not failed then
		return result.ok(nil)
	end

	io:write(`  Supported features:`)
	for feat, subs in pairs(featureSet) do
		io:write(`    {feat}:`)
		for _, typ in ipairs(subs) do
			io:write(`      {typ}`)
		end
	end

	return result.ok(nil)
end)