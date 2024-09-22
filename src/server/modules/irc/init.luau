--!strict
--[[
Name: irc.luau
Description: IRC client using proxy as only http/https is supported

Creator: SquelchMaster
Date: 9/10/2024 

Notes:
  Proxy backend should support batched calls to /status to allow for multiple clients at the same time on the same server
	Make a token.luau file with the API key
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Signal = require(ReplicatedStorage.Shared.Signal)
local schema = require(script.endpoints.schema)
local request = require(script.request)

local IRC = {
	errored = Signal.new() :: Signal.Signal<string>,
  status = Signal.new() :: Signal.Signal<schema.StatusResponse>,

  -- should we return the requests here?
  -- we just need to inform the user of changes
  updated = Signal.new() :: Signal.Signal<{schema.UpdateRequest<unknown>}, {schema.UpdateResponse}>,

  action = require(script.updateBuilder)
}

local updateQueue = {} :: {schema.UpdateRequest<unknown>}

local initialized = false
local paused = true

local connected = {
  currently = false,

  users = {},
  server = {}
}

local budget = {
  status = {
    limit = 0,
    remaining = 0,

    delay = 0,
    last = 0
  },

  update = {
    limit = 0,
    remaining = 0,

    delay = 0,
    last = 0
  },

  connection = {
    limit = 0,
    remaining = 0,
  },

  total = {
    limit = 0,
    remaining = 0,
  },

  pending = {status = 0, update = 0, connection = 0, total = 0},
  lastReset = 0,
}

local endpoints = {
  connect = require(script.endpoints.connect)
}

local utility = require(script.utility)

local function resetBudget()
  for stat, limit in pairs(budget.pending) do
    local data = budget[stat]
    data.limit = limit
    data.remaining = limit

    if data.delay then
      data.delay = 60/limit
    end
  end

  budget.lastReset = os.clock()
end

-- Updates whenever the budget resets (60s) 
function IRC.setRequestsPerMinute(status: number, update: number, connection: number)
  utility.inRange(status, 0, 500, `Expected 0-500 status requests, got {status}`)
  utility.inRange(update, 0, 500-status, `Expected 0-${500-status} update requests, got {update}`)
  utility.inRange(connection, 0, 500-status-update, `Expected 0-%{500-status-update} connection requests, got {connection}`)

  local total = status + update + connection
  utility.inRange(total, 0, 500, `Expected 0-500 total requests, got {total}`)

  budget.pending.status = status
  budget.pending.update = update
  budget.pending.connection = connection
  budget.pending.total = total
end

local function formatRequestStat(title: string, stat: string): string
  local pending = budget.pending[stat]
	local data = budget[stat]

	-- because typechecking complains that string.format() only takes 1 arg????
	local d = '%.2f'
	local used = data.limit - data.remaining

  local out = {
    title,
    `  Allocated: {data.limit}{if pending and pending ~= data.limit then `, Pending Update: {pending}` else ''}`,
    `  Remaining: {data.remaining} ({d:format((data.remaining / data.limit) * 100)}%), Used: {used} ({d:format((used / data.limit) * 100)}%)`,
  }

  return table.concat(out, '\n')
end

function IRC.printRequestStats()
  local output = {
    '',
    formatRequestStat("Status Requests", "status"),
		formatRequestStat("Update Requests", "update"),
		formatRequestStat("Connection Requests", "connection"),
		formatRequestStat("Total Requests", "total"),
  }
  
	print(table.concat(output, '\n'))
end

function IRC.queueUpdate(update: schema.UpdateRequest<unknown>)
	table.insert(updateQueue, update)
end

function IRC.connect(host: string, port: number, secure: boolean)
	local success, response = endpoints.connect(host, port, secure)

  if success and response.StatusCode == 200 then
    local data: schema.ConnectionResponse = HttpService:JSONDecode(response.Body)

    connected.currently = true
    connected.server = data.server
  end
end

function IRC.pause()
	paused = true
end

function IRC.resume()
	if not initialized then
		initialized = true
		resetBudget()
	end

	paused = false
end

local clock = os.clock
local connection
connection = RunService.Heartbeat:Connect(function()
	if not initialized then return end

	local now = clock()

	if (now - budget.lastReset) > 60 then
		resetBudget()
	end
	
	if paused then return end
  if not connected.currently then return end

  if (now - budget.status.last) > budget.status.delay then
		budget.status.last = now

    local success, response = request('status', 'GET')
    budget.status.remaining -= 1
    budget.total.remaining -= 1

    if not success then
      -- warn("status failed", success, response)
      IRC.errored:Fire(response.Body :: string)
    end

    if response.StatusCode == 200 then
      IRC.status:Fire(HttpService:JSONDecode(response.Body))
    end
  end

  if (now - budget.update.last) > budget.update.delay then
    budget.update.last = now

    if #updateQueue > 0 then
      local success, response = request('update', 'POST', updateQueue)
      budget.update.remaining -= 1
      budget.total.remaining -= 1

      if not success then
        IRC.errored:Fire(response.Body :: string)
        -- warn("update failed", success, response)
      end

      if response.StatusCode == 200 then
        IRC.updated:Fire(table.clone(updateQueue), HttpService:JSONDecode(response.Body))

        table.clear(updateQueue)
      end


    end
  end
end)

-- Should only bind to game closing aa
function IRC.disconnect()
	initialized = false

	connection:Disconnect()
	connection = nil
	
	request('close', 'GET')
end

return IRC