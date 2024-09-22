local ServerStorage = game:GetService("ServerStorage")

local IRC = require(ServerStorage.irc)

-- game:BindToClose(IRC.disconnect)

IRC.setRequestsPerMinute(400, 80, 20)
IRC.resume()

IRC.printRequestStats()

IRC.status:Connect(function(response)
    for host, server in pairs(response.servers) do
        for _, user in pairs(server.users) do
            if #user.output > 0 then
                print(`Output: {user.name}`)
                for _, msg in ipairs(user.output) do
                    print(`{msg.command}({msg.rawCommand}):`, msg)
                end
            end
        end
    end
    -- print(`Got status!`, response)
end)

IRC.errored:Connect(function(err)
    warn(`Encountered error: {err}`)
end)

IRC.updated:Connect(function(requests, responses)
    print("IRC server processed requests", requests, "and responded with", responses)
end)

IRC.connect('irc.beenman.com', 6697, true)

task.wait(1)
print("lets try to add a user")

IRC.queueUpdate(IRC.action.userUpdate('SquelchMaster', 'beanie', 'add', 'irc.beenman.com'))