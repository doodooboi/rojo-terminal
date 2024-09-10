local RSDOS = script.Parent.Parent

local config = require(RSDOS.components.config)
local types = require(RSDOS.types)
local fs = require(RSDOS.fs)

local structure = {
	['/boot'] = {
		['init.d'] = {}
	},
	["/bin"] = {
		
	},
	["/home"] = {
		[`/{config.HomeDirectory}`] = {
			home = true,
			
			["init.d"] = {contents = '\"Hello, World!\"'},
			["/music"] = {
				['/default'] = {
					["epic beats.mp3"] = {contents = "rbxassetid://5887017563"},
					["heart.mp3"] = {contents = "rbxassetid://1837736042"}
				}
			}
		}		
	},
}

local root = {
	root = true,
	class = 'directory',
	back = '/',
	
	contents = {}
} :: types.Directory

local function populate(root: {[string]: any}, parentDirectory)
	for index, value in pairs(root) do
		if typeof(value) == "boolean" then continue end
		
		if index:sub(1,1) == "/" then
			local result = fs.mkdir(index:sub(2), parentDirectory)
			
			if result.type == 'err' then
				error(result.err)
			end
			
			if value.home then
				result.value.home = true
			end
			
			populate(value, result.value)
		else
			local result = fs.mkfile(index, value.contents, parentDirectory, value.desc)
			
			if result.type == 'err' then
				error(result.err)
			end
		end
	end
end

populate(structure, root)

return root