--[[
Name: utility.luau
Description: Simple helper functions used by commands

Creator: SquelchMaster
Date: 08/03/2024 
]]

local Utility = {}
local concat = table.concat

Utility.tableToString = require(script.tableToString)

local types = require(script.Parent.types)

function Utility.getFlag(flag: string): string?
	if not flag then return end
	-- my gosh, ill never f###### understand why we cant have RegEX??? noooo
	-- lets have stupid string patterns like this, rather than a more understood and readable format
	-- ah yes % instead of \ as an escape, no way to allow up to n matches using {1,4}
	
	return flag:match("^%-%-?([^-].*)")
end

function Utility.whatIs(s: string): 'file' | 'directory' | 'unknown'
	if #s < 1 then return 'unknown' end
	if s == '.' or s == '..' then return 'directory' end
	
	return if s:match("%.") then 'file' else 'directory'
end

function Utility.filter<T>(array: {T}, filterer: (value: T) -> boolean)
	for i, value in ipairs(array) do
		if not filterer(value) then table.remove(array, i) end
	end
end

function Utility.stripRichtext(s: string): string
	local stripped = s:gsub("%b<>", "")

	return stripped
end

@native
function Utility.concat<T>(tbl: {T}, sep: string?, start: number?, stop: number?): string
	start = start or 1
	stop = stop or #tbl
	
	local str = {}
	
	for i = (start :: number), (stop :: number) do
		local got = tbl[i]
		if not got then continue end
		
		table.insert(str, tostring(got))
	end
	
	return concat(str, sep)
end

function Utility.splitSpacePreserveQuotes(s: string): {string}
	local result = {}
	local current_word = ""
	local in_quotes = false

	for i = 1, #s do
		local char = s:sub(i, i)

		if char == '"' then
			if in_quotes then
				-- End of quoted string
				in_quotes = false
				table.insert(result, current_word)
				current_word = ""
			else
				-- Start of quoted string
				in_quotes = true
			end
		elseif char == ' ' and not in_quotes then
			if #current_word > 0 then
				table.insert(result, current_word)
				current_word = ""
			end
		else
			current_word = current_word .. char
		end
	end

	if #current_word > 0 then
		table.insert(result, current_word)
	end

	return result
end

function Utility.toHHMMSS(seconds: number)
	local hours = (seconds / 3600) // 1
	local minutes = ((seconds % 3600) / 60) // 1
	local secs = seconds % 60

	if hours > 0 then
		return string.format("%02d:%02d:%02d", hours, minutes, secs)
	else
		return string.format("%02d:%02d", minutes, secs)
	end
end

function Utility.toArray(dict: types.Map<any, any>, sorter: ((a: any, b: any) -> boolean)?)
	local tbl = {}
	
	for key, value in pairs(dict) do
		table.insert(tbl, {key = key, value = value})
	end

	if sorter then
		table.sort(tbl, sorter)
	end

	return tbl
end

return Utility
