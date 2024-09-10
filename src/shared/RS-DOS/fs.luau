--[[
Name: fs.luau
Description: Manages all interactions with the rootfs and provides helpers for making objects

Creator: SquelchMaster
Date: 08/03/2024 
]]

local Player = game.Players.LocalPlayer :: Player

local RSDOS = script.Parent

local Types = require(RSDOS.types)

local result = require(RSDOS.result)
local config = require(RSDOS.components.config)

local FileSystem = {}

type Descriptor = {
	owner: string?, 
	created: number?, 

	permissions: Types.Map<string, string>?
}

local function parent(owner: Types.Directory, child: Types.Directory)
	if owner.root then
		child.back = '/'
		return
	end
	
	child.back = string.gsub(`{owner.back}/{owner.name}`, "//", "/")
end

function FileSystem.mkdir(
	name: string, 
	location: Types.Directory, 
	
	descriptor: Descriptor?,
	bypass: boolean?
): Types.Result<Types.Directory, string>
	local desc = (descriptor or {}) :: Descriptor
	
	if not bypass then
		if table.find(config.ReservedNames, name) then
			return result.err(`'{name}' is a reserved name!`)
		end
		
		if location.contents[`/{name}`] then
			return result.err("Directory already exists!")
		end
	end
	
	local directory: Types.Directory = {
		name = name,
		class = 'directory',

		metadata = {
			size = 0,
			path = "",

			created = desc.created or DateTime.now().UnixTimestampMillis,
		},

		security = {
			permissions = desc.permissions or {},
			owner = desc.owner or Player.Name:lower()
		},

		contents = {},
		back = ""
	}
	
	parent(location, directory)
	location.contents[`/{name}`] = directory
	
	return result.ok(directory)
end

function FileSystem.mkfile(
	name: string, 
	contents: string, 
	location: Types.Directory,
	
	descriptor: Descriptor,
	overwrite: boolean?
): Types.Result<Types.File, string>
	contents = contents or ""
	descriptor = descriptor or {}
	
	local fileName, extension = name:match("^(.*)%.([^%.]+)$")
	if not fileName or not extension then
		return result.err(`Invalid file format! expected: name.extension, got: '{fileName}.{extension}'`)
	end
	
	if not overwrite and location.contents[name] then
		return result.err(`File {name} already exists!`)
	end
	
	local file: Types.File = {
		name = fileName,
		extension = extension,
		
		class = 'file',

		contents = contents,

		metadata = {
			created = descriptor.created or DateTime.now().UnixTimestampMillis,
			path = string.gsub(`{location.back}/{location.name}/{name}`, "//", "/"),

			size = #contents
		},

		security = {
			owner = descriptor.owner or Player.Name:lower(),
			permissions = {}
		}
	}

	location.contents[name] = file
	return result.ok(file)
end

function FileSystem.rm()
	
end

function FileSystem.stats(path: string)
	
end

return FileSystem
