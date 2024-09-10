local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local RSDOS = ReplicatedStorage["RS-DOS"]
local Resources = ReplicatedStorage.Resources

local paneManager = require(ReplicatedStorage.paneManager)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

local PlayerGui: PlayerGui = Player:WaitForChild("PlayerGui")
local Terminal = PlayerGui:WaitForChild("Terminal") :: ScreenGui

-- local io = require(RSDOS.iostream)
local bin = require(RSDOS.bin)
-- local path = require(RSDOS.path)
local types = require(RSDOS.types)
local result = require(RSDOS.result)

local config = require(RSDOS.components.config)
local xterm256 = require(RSDOS.components.xterm256)

local panes = paneManager.attach(Terminal.Container :: Frame, Resources.Pane)

local function scrollToBottom(scrolling: ScrollingFrame)
	scrolling.CanvasPosition = Vector2.new(0, scrolling.AbsoluteCanvasSize.Y)
end

-- Needed to safely edit textbox.Text without funky control characters
local function safeSetText(textBox: TextBox, text: string, location: string, overridePos: boolean?)
	textBox:SetAttribute("_ignoresignal", true)

	local difference = #text - textBox.CursorPosition

	if #text:gsub("^%s", "") == 0 then
		difference = -1
	end

	textBox.Text = text
	textBox.CursorPosition = if overridePos then #text + 1 else math.max(#text - difference, #location + 3)
	textBox:SetAttribute("lastText", text)
	task.wait()

	textBox:SetAttribute("_ignoresignal", nil)
end

local function updateTerminalDirectory(pane: types.pane)
	local directory = pane.at.directory
	local str = { `{xterm256(`{Player.Name:lower()}@localhost`, 41)}:` }

	if directory.root then
		table.insert(str, "/")
	else
		local fullPath = `{directory.back}/{directory.name}`
		fullPath = fullPath:gsub(`^/home/{config.HomeDirectory}`, "~")

		table.insert(str, fullPath)
	end

	-- blue
	pane.at.pwd = str[2]:gsub("^~", `/home/{config.HomeDirectory}`):gsub("/+", "/")
	str[2] = xterm256(str[2], 39):gsub("/+", "/")
	table.insert(str, "$")

	local final = table.concat(str)
	local UI = pane:getUI()

	pane.at.path = final
	UI.Input.where.Text = final
end

local function onTextChanged(override: boolean?)
	local pane = panes:getFocused()
	local UI = pane:getUI() :: ScrollingFrame

	local input = UI.Input.input :: TextBox
	local location = UI.Input.where :: TextLabel

	if input:GetAttribute("_ignoresignal") then
		return
	end
	-- So we cant edit the text while invisible (processing)
	if not UI.Input.Visible then
		input.Text = input:GetAttribute("lastText")
		return
	end

	local text = input.Text:gsub("^%s+", "")
	local offset = #location.ContentText + 1

	safeSetText(input, `{string.rep(" ", offset)}{text}`, location.ContentText, true)
	scrollToBottom(UI)
end

local function lockCursorPosition()
	local pane = panes:getFocused()
	local UI = pane:getUI()

	local input = UI.Input.input :: TextBox
	local location = UI.Input.where :: TextLabel

	local pos = input.CursorPosition
	if pos == -1 then
		return
	end

	local offset = #location.ContentText + 2
	if pos < offset then
		input.CursorPosition = offset
	end
end

local function focusLost(pane: types.pane, enter: boolean)
	local UI = pane:getUI()

	local input = UI.Input.input :: TextBox
	local location = UI.Input.where :: TextLabel
	
	-- warn(enter)

	-- Needed because textboxes are funky with capture focus same frame
	task.wait()
	local focused = UserInputService:GetFocusedTextBox()

	-- Make sure we can select output for copy and paste
	if not enter and (not focused or (focused and focused.Name ~= "output")) then
		input:CaptureFocus()
		return
	end

	if pane.running and pane.IOManager.stdin.waiting then
		if not enter then
			input:CaptureFocus()
			return
		end

		local got = input.Text:gsub("^%s+", "")
		pane.IOManager:write(`{location.Text} {got}`)

		input.Text = ""
		UI.Input.Visible = false
		-- (UI.Input.where :: TextBox).FontFace.Weight = Enum.FontWeight.Bold
		
		pane.IOManager.stdin.recieve:Fire(got)
		return
	end
	-- Don't handle a command if we cant physically enter one
	if not enter or not UI.Input.Visible then
		return
	end

	input:CaptureFocus()

	-- Spawn a new thread so commands may loop
	task.spawn(function()
		pane._rememberIndex = 0
		
		local given = input.Text:gsub("^%s+", "")
		local IO = pane.IOManager

		-- Write to history
		IO:write(`{location.Text} {given}`)
		pane:remember(given)

		-- Clear input
		input.Text = ""
		input:SetAttribute("lastText", "")

		if #given ~= 0 then
			local command = given:split(" ")[1]
			UI.Input.Visible = false

			pane.signals.processed:Once(function(res)
				UI.Input.Visible = true

				pane:_recalculateMaxCharacters()

				-- General cleanup
				pane.janitor:Cleanup()
				pane.running = nil

				if IO._swapped then
					IO:flush(true)
					IO:swap()
				end

				if res.type == "err" then
					IO:write(`{command}: command not found`)
				else
					local commandResult = res.value

					if commandResult.type == "err" then
						IO:write(`{command}: {commandResult.err}`)
					end
				end
				-- Clear memory labels
				IO:flush()
				-- Allow updating to buffer incase command deferred and never resumed updates
				IO:deferUpdates(false)

				-- Just to be safe?
				updateTerminalDirectory(pane)
				onTextChanged()
			end)

			-- We used to return a Result<> but now a signal callback is used instead
			-- Allows for the use of task.cancel on the running thread and perform cleanup simply
			bin(given, false, pane)
		else
			-- Just to be safe?
			updateTerminalDirectory(pane)
			onTextChanged()
		end
	end)
end

-- Update real and fake text accordingly
local function updateIOBuffer(pane: types.pane, text: string, forced: boolean?)
	local UI = pane:getUI()

	local fake = UI.output :: TextBox
	local real = fake.real :: TextLabel

	real.Text = text

	local fakeText = real.ContentText:gsub("[^\n]", " ")
	fake.Text = fakeText

	scrollToBottom(UI)
end

-- Setup connections for pane events
panes.paneFocused:Connect(function(pane, event)
	local UI = pane:getUI()

	local input = UI.Input.input :: TextBox

	if event == "focused" then
		pane:track(input:GetPropertyChangedSignal("CursorPosition"):Connect(lockCursorPosition))
		pane:track(input:GetPropertyChangedSignal("Text"):Connect(onTextChanged))
		pane:track(input.FocusLost:Connect(function(enter)
			focusLost(pane, enter)
		end))

		panes:setFocused(pane)

		-- Prevent weird textbox issues *cough roblox cough*
		task.wait()

		input:CaptureFocus()
		onTextChanged()
	end
end)

panes.paneCreated:Connect(function(pane)
	local UI = pane:getUI()
	local output = UI.output :: TextBox

	local function _focus(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end

		local oldPane = panes:getFocused()
		if oldPane == pane then
			return
		end

		oldPane:unfocus()
		pane:focus()
	end

	-- Focus new pane when clicked on
	pane:track(UI.InputBegan:Connect(_focus), true)
	pane:track(output.InputBegan:Connect(_focus), true)

	pane:track(
		pane.IOManager.stdin.request:Connect(function()
			-- (UI.Input.where :: TextBox).FontFace.Weight = Enum.FontWeight.Regular
			UI.Input.where.Text = pane.IOManager.stdin.prefix
			onTextChanged()

			UI.Input.Visible = true
		end),
		true
	)

	-- Update pane's output
	pane:track(
		pane.IOManager.updated:Connect(function(forced)
			UI.output.Visible = pane.IOManager:size() > 0

			if forced then
				warn("Forced update requested")
			end

			updateIOBuffer(pane, pane.IOManager:render(), forced)

			if forced then
				warn("Updated")
			end
		end),
		true
	)

	-- Listen to SIGKILl
	pane:track(
		pane.signals.SIGKILL:Connect(function()
			if not pane.running then
				return
			end

			task.cancel(pane.running)
			pane.signals.processed:Fire(result.ok(result.ok(nil)))
		end),
		true
	)

	local errors = bin.errors()
	if #errors > 0 then
		local output = { xterm256(`{#errors} commands failed to load:`, 88) }

		for _, err in ipairs(errors) do
			table.insert(output, `  {err}`)
		end

		pane.IOManager:write(table.concat(output, "\n"))
		updateIOBuffer(pane, pane.IOManager:render())
	else
		updateIOBuffer(pane, "")
	end

	updateTerminalDirectory(pane)
end)

local function updateOffset()
	local inset = GuiService.TopbarInset

	Terminal.Container.Position = UDim2.new(0.5, 0, 0, inset.Max.Y)
	Terminal.Container.Size = UDim2.new(1, -10, 1, -(inset.Max.Y + 5))
end

GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(updateOffset)
panes:start()
-- updateTerminalDirectory()

UserInputService.InputBegan:Connect(function(input)
	local holdingAlt = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
		or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)

	local holdingControl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
		or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)

	if holdingAlt and holdingControl and input.KeyCode == Enum.KeyCode.I then
		local pane = panes:getFocused()
		if not pane then
			return
		end

		print("Forcing IO update")
		pane.IOManager.updated:Fire(true)

		return
	end

	if holdingAlt then
		panes:split(input.KeyCode.Name:lower())
		return
	elseif holdingControl then
		local currentPane = panes:getFocused()
		-- Handle SIGINT (Safely let applications exit)
		if input.KeyCode == Enum.KeyCode.C then
			currentPane.signals.SIGINT:Fire()
			return
		-- Handle SIGKILL (Force it to end immediately)
		elseif input.KeyCode == Enum.KeyCode.X then
			currentPane.signals.SIGKILL:Fire()
			return
		end
	end

	local pane = panes:getFocused()
	if not pane.running and (input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.Down) then
		local saved = pane:getSaved(input.KeyCode.Name:lower())

		if saved then
			local input = pane:getUI().Input.input :: TextBox
			input:SetAttribute("_ignoresignal", true)

			input.Text = saved

			input:SetAttribute("_ignoresignal", false)
			onTextChanged(true)
		end
	end
end)

-- Capture focus back when done selecting text
UserInputService.TextBoxFocusReleased:Connect(function(textbox)
	if textbox.Name ~= "output" then
		return
	end

	local pane = panes:getPaneByFrame(textbox:FindFirstAncestor("Pane"))
	if not pane then
		return
	end

	local UI = pane:getUI()
	UI.Input.input:CaptureFocus()
end)

-- Fix copying
RunService.Heartbeat:Connect(function()
	local focused = UserInputService:GetFocusedTextBox()

	local success = pcall(function()
		return focused.Name
	end)
	if not success then
		return
	end

	if focused and focused.Name == "output" then
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			focused.Text = focused.real.ContentText
		else
			focused.Text = focused.real.ContentText:gsub("[^\n]", " ")
		end
	end
end)
