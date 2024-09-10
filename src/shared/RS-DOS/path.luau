--[[
Name: path.luau
Description: Resolves paths to either a directory or file

Creator: SquelchMaster
Date: 08/03/2024 
]]

local RSDOS = script.Parent
local Types = require(RSDOS.types)

local result = require(RSDOS.result)
local utility = require(RSDOS.utility)

local config = require(RSDOS.components.config)
local rootfs = require(RSDOS.components.rootfs)

local Path = {}

local function periodFilterer(s: string)
	return s ~= "."
end

--[[
Resolve an absolute or relative path to a file or directory
]]
function Path.resolve(path: string, current: Types.Directory?): Types.Result<Types.Directory | Types.File, string>
	path = path:gsub("/+", "/")
	
	local pointer = current or rootfs 
	local fragments = path:split("/")
	
	utility.filter(fragments, periodFilterer) -- Remove singular periods
	local currentFragment = table.remove(fragments, 1)

	-- path: /; split = {"", ""}
	if currentFragment == '' and #fragments >= 1 then
		pointer = rootfs
		currentFragment = table.remove(fragments, 1)
	elseif currentFragment == '~' then
		pointer = rootfs.contents['/home'].contents[`/{config.HomeDirectory}`]
		currentFragment = table.remove(fragments, 1)
	end
	
	-- we only did just ~ or /
	if not currentFragment or #currentFragment == 0 then
		return result.ok(pointer)
	end
	
	if currentFragment == '..' then
		return Path.resolve(`{pointer.back}/{table.concat(fragments, '/')}`)
	end

	local constructed = if utility.whatIs(currentFragment) == 'directory' then `/{currentFragment}` else currentFragment
	pointer = pointer.contents[constructed]
	
	if not pointer then
		return result.err(`No such file or directory`)	
	end
	
	if pointer.class == 'file' and #fragments > 1 then
		return result.err(`Cannot resolve directory from file {constructed}`)
	end
	
	if #fragments >= 1 then
		return Path.resolve(table.concat(fragments, '/'), pointer)
	end
	
	return result.ok(pointer)
end

return Path
