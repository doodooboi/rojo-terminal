local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RSDOS = ReplicatedStorage["RS-DOS"]

local types = require(RSDOS.types)
local pane = require(script.pane)

local defaultSplitName = "Split"

local paneManager: types.impl_paneManager = {
	paneFocused = pane.paneFocusEvent,
	paneCreated = pane.paneCreated
} :: types.impl_paneManager

paneManager.__index = paneManager

local function createSplitFrame(): Frame
	local frame = Instance.new('Frame')
	frame.BackgroundTransparency = 1
	frame.Name = defaultSplitName
	
	return frame
end

function paneManager.attach(container, template)
	local clone = template:Clone()
	local initalPane = pane.new(container, clone)

	local self: types.paneManager = setmetatable({
		template = template,
		focused = initalPane,
		
		container = container,

		_panes = {},
		_lookup = {[clone] = initalPane}
	}, paneManager)

	return self
end

function paneManager:getPaneByFrame(frame)
	return self._lookup[frame]
end

-- lol weird, but it has to fire the focus event
function paneManager:start()
	self.focused:focus()
	paneManager.paneCreated:Fire(self.focused)
end

function paneManager:setFocused(newPane: types.pane)
	self.focused = newPane
end

function paneManager:getFocused()
	return self.focused
end

function paneManager:split(direction)
	local paneUI = self.focused:getUI()
	local focused = paneUI:FindFirstAncestor(defaultSplitName) or self.container :: Frame

	local vertical = direction == 'up' or direction == 'down'
	local horizontal = direction == 'left' or direction == 'right'

	if not vertical and not horizontal then return end

	local mainFrame = createSplitFrame()
	local newFrame = createSplitFrame()
	
	-- focused.BackgroundTransparency = 1
	if vertical then
		local newSize = UDim2.fromScale(1, 0.5)

		mainFrame.Size = newSize
		newFrame.Size = newSize

		-- Create a pane below, current remains up
		if direction == 'down' then
			mainFrame.Position = UDim2.fromScale(0, 0)
			newFrame.Position = UDim2.fromScale(0, 0.5)
		else -- Create a pane above, current goes down
			mainFrame.Position = UDim2.fromScale(0, 0.5)
			newFrame.Position = UDim2.fromScale(0, 0)
		end
	else
		local newSize = UDim2.fromScale(0.5, 1)

		mainFrame.Size = newSize
		newFrame.Size = newSize

		-- Create a pane to the right, current remains left
		if direction == 'right' then
			mainFrame.Position = UDim2.fromScale(0, 0)
			newFrame.Position = UDim2.fromScale(0.5, 0)
		else -- Create a pane to the left, current goes to the right
			mainFrame.Position = UDim2.fromScale(0.5, 0)
			newFrame.Position = UDim2.fromScale(0, 0)
		end
	end

	-- okay wtf you NEED to do this or else it'll set input text to nil
	mainFrame.Parent = focused
	newFrame.Parent = focused

	-- move the old pane to the 	
	self.focused:reparent(mainFrame)
	self.focused:unfocus()

	self.focused:_recalculateMaxCharacters()
	self.focused.signals.resized:Fire()

	local cloned = self.template:Clone()
	local newPane = pane.new(newFrame, cloned)
	
	self.focused = newPane
	self._lookup[cloned] = newPane
	
	newPane:focus()
end

function paneManager:close(all)
	if all then
		
	end
end

return paneManager