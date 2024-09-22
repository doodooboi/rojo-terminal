local schema = require(script.Parent.endpoints.schema)

local builder = {}

function builder.userUpdate(
    name: string, nick: string, 
    action: 'add' | 'remove', host: string
): schema.UpdateRequest<schema.UserUpdateRequest>
    return {
        params = {
            host = host,
            user = name,
            nick = nick,

            action = action,
        },

        type = 'user'
    }
end

return builder