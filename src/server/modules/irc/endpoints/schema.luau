--!strict
--[[
Name: irc/endpoints/schema.luau
Description: All endpoints typed fully

Creator: SquelchMaster
Date: 9/16/2024 
]]

local validUpdateTypes = {'user', 'speak', 'part', 'pm', 'whois'}

export type UpdateRequest<T> = {
    -- waiting for luau-lsp to update with new typechecking features
	-- type: keyof<validUpdateTypes, number>,
    type: 'user' | 'speak' | 'part' | 'pm' | 'whois',
	params: T & {host: string}
}

export type UserUpdateRequest = {
    nick: string,

    action: 'add' | 'remove'
}

export type UpdateResponse = {
	type: 'err' | 'ok',
	err: string?
}

export type RawMessage = {
    args: {string},
    commandType: string, --"reply",
    prefix: string, --"irc.beenman.com",
    command: string, --"rpl_channelmodeis",
    rawCommand: string, --"324"
  }

export type User = {
    name: string,
    nick: string,
    real: string,

    output: {RawMessage}
}

export type Server = {
	secure: boolean,

	host: string,
	port: number,

	orgIP: string,
}

export type ConnectionResponse = {
	ip: string,

	server: Server
}

export type StatusResponse = {
	ip: string,

	servers: {[string]: {
		server: Server,
		users: {User}
	}}
}

local schema = {}

local subValidators = {
	update = {
		user = function(request: UpdateRequest<UserUpdateRequest>): boolean
			
			
			return true
		end
	}
}
local function validateUpdateRequest(data: UpdateRequest<unknown>): boolean
	if not table.find(validUpdateTypes, data.type) then 
		warn(`Invalid UpdateRequest: Invalid type, expected: [{table.concat(validUpdateTypes, ', ')}], got {data.type}`)
		return false 
	end

	if not data.params then
		warn(`Invalid UpdateRequest: Missing params, expected: \{user: string}, got nil`)
		return false 
	end

	if data.type == 'user' then
		return subValidators.update.user(data :: UpdateRequest<UserUpdateRequest>)
	end

	return true
end

function schema.validate(what: 'UpdateRequest', data: any): boolean
	if what == 'UpdateRequest' then
		return validateUpdateRequest(data)
	end

	return true
end

return {}