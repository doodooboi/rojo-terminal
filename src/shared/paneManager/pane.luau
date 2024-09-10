local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local RSDOS = ReplicatedStorage["RS-DOS"]
local Shared = ReplicatedStorage.Shared


local types = require(RSDOS.types)

local sharedTypes = require(RSDOS.types)
local iostream = require(RSDOS.iostream)
local path = require(RSDOS.path)

local audioBus = require(RSDOS.drivers.audio)

local Signal = require(Shared.Signal)
local Janitor = require(Shared.Janitor)

local pane: types.impl_pane = {
	paneFocusEvent = Signal.new(),
	paneCreated = Signal.new()
} :: types.impl_pane
pane.__index = pane

function pane.new(parent, UI)
	local home = path.resolve('~') :: sharedTypes.Ok<sharedTypes.Directory>

	local self: types.pane = setmetatable({
		ui = UI,
		parent = parent,

		focused = true,
		yielded = false,

		at = {
			directory = home.value,
			path = "~",
			pwd = ''
		},

		janitor = Janitor.new(),

		max_x = 0,
		max_y = 0,

		connections = { 
			pane = {}, 
			focused = {},
			running = {}
		},

		signals = {
			SIGINT = Signal.new(),
			SIGKILL = Signal.new(),

			resized = Signal.new(),
			processed = Signal.new(),
		},

		history = {},

		IOManager = iostream.new(),
		AudioBus = audioBus.new(),

		_rememberIndex = 0,
	} , pane)

	UI.Parent = parent
	pane.paneCreated:Fire(self)

	self:_recalculateMaxCharacters()

	return self
end

function pane:remember(command)
	if #command == 0 then return end
	if self.history[1] == command then return end

	table.insert(self.history, 1, command)

	if #self.history > 100 then
		table.remove(self.history, #self.history)
	end
end

function pane:getSaved(direction)
	self._rememberIndex += if direction == 'up' then 1 else -1
	self._rememberIndex = math.clamp(self._rememberIndex, 1, math.max(1, #self.history))

	return self.history[self._rememberIndex]
end

function pane:close()
	
end

function pane:reparent(newParent)
	self.ui.Parent = newParent
end

function pane:track(connection, tillPaneClosed)
	local list = self.connections.focused
	if tillPaneClosed then
		list = self.connections.pane
	end

	table.insert(list, connection)
end

function pane:focus()
	self.focused = true

	pane.paneFocusEvent:Fire(self, 'focused')
end

function pane:unfocus()
	self.focused = false

	for _, connection in ipairs(self.connections.focused) do
		connection:Disconnect()
	end
	
	self.connections.focused = {}
	pane.paneFocusEvent:Fire(self, 'unfocused')
end

function pane:getUI()
	return self.ui
end

function pane:_recalculateMaxCharacters(char)
	local UI = self.ui

	local params = Instance.new("GetTextBoundsParams")
	params.Font = UI.output.real.FontFace
	params.Size = UI.output.real.TextSize
	params.Text = char or "A"
	params.Width = 200
	
	local absoluteSize = UI.AbsoluteSize
	local charSize = TextService:GetTextBoundsAsync(params)
	
	self.max_x = absoluteSize.X // charSize.X
	self.max_y = absoluteSize.Y // charSize.Y

	params:Destroy()
end

return pane