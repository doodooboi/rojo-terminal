--!strict
local HttpService = game:GetService("HttpService")

local schema = require(script.Parent.schema)
local request = require(script.Parent.Parent.request)

return function(requests: {schema.UpdateRequest<unknown>})
    local success, response = request('update', 'POST', requests)

    if success and response.StatusCode == 200 then
        local body = HttpService:JSONDecode(response.Body) :: {schema.UpdateResponse}

        for index, uresponse in ipairs(body) do
            print(index, uresponse)
        end
    end
end