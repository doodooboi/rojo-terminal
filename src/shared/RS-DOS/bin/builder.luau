local Types = require(script.Parent.Parent.types)

local Builder = {}

function Builder.create(
	descriptor: {
		name: string,
		description: string,
		
		aliases: {string}?,
	}, 
	arguments: {Types.Argument}, 
	callback: Types.CommandCallback
): Types.Command
	if not callback then error(`Must provide callback for command '{descriptor.name}'`) end
	
	return {
		name = descriptor.name,
		aliases = descriptor.aliases,
		
		arguments = arguments or {},
		callback = callback,
		
		description = descriptor.description
	}
end

function Builder.argument(name: string, description: string, optional: boolean?): Types.Argument
	return {name = name, description = description, optional = optional}
end

return Builder
