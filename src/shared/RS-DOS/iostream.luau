--[[
Name: iostream.luau
Description: Allows for commands to safely write to stdout with features like pushing, modifying and swapping buffers
Buffers exist so panes can have their own stdout

Creator: SquelchMaster
Date: 08/04/2024 
]]

--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared

local Signal = require(Shared.Signal)

local RSDOS = script.Parent
local types = require(RSDOS.types)
local utility = require(RSDOS.utility)

local IO: types.impl_IOManager = {} :: types.impl_IOManager
IO.__index = IO

function IO.new()
	return setmetatable({
		buffer = {},
		memory = {},
		
		buffering = false,
		updated = Signal.new(),

		stdin = {
			prefix = "",
			waiting = false,

			request = Signal.new(),
			recieve = Signal.new()
		},
	
		_swapBuffer = {},
		_swapMemory = {},

		_swapped = false,
		_reserved = false
	}, IO)
end

--[[ 
Outputs text to stdout
Param: label: editing past text, ex: progress bar
]]
function IO:write(text, label)
	local length = self:size()
	local index = 0

	-- localize to save __index time
	local memory = self.memory

	if label then
		local memorized = memory[label]
		if not memorized then
			memory[label] = length + 1
			index = length + 1
		else
			index = memorized
		end
	else
		index = length + 1
	end

	if length > 500 then
		table.remove(self.buffer, 1)

		index -= 1 
		for savedLabel in pairs(memory) do
			memory[savedLabel] -= 1
		end
	end

	self.buffer[index] = text
	if not self.buffering then
		self.updated:Fire()
	end


	return index
end

--[[
Allows modification of buffer without firing update signal when deffered
]]
function IO:deferUpdates(enabled, update)
	self.buffering = enabled

	if not enabled then
		self.updated:Fire()
	end
end

--[[
Reserves space in buffer for future editing, without the fear of overridding future output
Allocates empty strings in place 
]]
function IO:reserve(count)
	return -1, -1
end

--[[
Removes line from buffer, and pushes it to the bottom, returns new index
Use case: Progress bar at bottom of command and outputting above it
]]
function IO:push(label)
	local memory = self.memory
	local memorized = if label then memory[label] else nil

	if not memorized then
		error(`[IO::push]: Invalid label '{label}'`)
		return -1
	end
	
	-- Remove from memory, so we don't accidentally modify the same line
	-- It'll just get re-added anyways
	memory[label] = nil
	
	local removed = table.remove(self.buffer, memorized) :: string
	for savedLabel in pairs(memory) do
		memory[savedLabel] -= 1
	end


	return self:write(removed, label)
end

--[[
Swap primary and back buffer to allow clean command output without affecting
primary buffer, fires update signal unless deferred
]]
function IO:swap()
	self._swapped = not self._swapped

	-- swap buffers
	local tempbuf = self.buffer
	self.buffer = self._swapBuffer
	self._swapBuffer = tempbuf

	-- swap memory labels
	local tempmem = self.memory
	self.memory = self._swapMemory
	self._swapMemory = tempmem

	if not self.buffering then
		self.updated:Fire()
	end
end

--[[
[ASYNC] Reads input from user, optionally prefixing text and pattern matching
]]
function IO:read(text, pattern)
	self.stdin.prefix = text or ""
	self.stdin.pattern = pattern
	self.stdin.waiting = true

	self.stdin.request:Fire()
	-- print(`sent request to read stdin with text: {text}, pattern: {pattern}`)

	local got = self.stdin.recieve:Wait()
	self.stdin.waiting = false
	self.stdin.pattern = nil
	self.stdin.prefix = ""
	
	-- print(`got stdin: {got}`)

	return got
end

--[[
Clear contents of buffer
Param: stdout (bool): if the text buffer also gets cleared
]]
function IO:flush(stdout)
	self.memory = {}
	
	if stdout then
		self.buffer = {}
		self.updated:Fire()
	end
end

function IO:size()
	return #self.buffer
end

local concat = table.concat
-- concat2 solves holes in arrays
local concat2 = utility.concat
function IO:render()
	if self._reserved then
		return concat2(self.buffer, '\n')
	else
		return concat(self.buffer, '\n')
	end
end

return IO

