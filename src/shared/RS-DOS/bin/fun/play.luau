local RSDOS = script:FindFirstAncestor("RS-DOS")
local CommandBuilder = require(script:FindFirstAncestor("bin").builder)

local utility = require(RSDOS.utility)
local result = require(RSDOS.result)
local path = require(RSDOS.path)

local xterm256 = require(RSDOS.components.xterm256)

return CommandBuilder.create({
	name = 'play',
	aliases = {'listen'},
	description = "Play any audio file/id"
}, {}, function(elevated, args, io, pane)
	io:swap()

	local interrupted = false
	pane.janitor:Add(pane.signals.SIGINT:Connect(function()
		interrupted = true
	end), "Disconnect")

	if not args[1] then
		return result.err("Must provide audio file or id")
	end

	local trackID: string = ""
	local resolvedFile = path.resolve(args[1], pane.at.directory)

	if resolvedFile.type == 'ok' then
		if resolvedFile.value.class == 'directory' then
			return result.err(`{args[1]}: Is a directory`)
		end

		if resolvedFile.value.extension ~= 'mp3' then
			return result.err(`{args[1]}: Not an audio file`)
		end

		trackID = resolvedFile.value.contents
	else
		trackID = args[1]
	end

	local stream = pane.AudioBus:stream(trackID)
	if stream.type == 'err' then
		return stream
	end

	pane.AudioBus:setGlobalVolume(0.01)

	local length = stream.value.player.TimeLength
	local lengthStr = utility.toHHMMSS(length)

	local max_x = 0

	local function setup()
		io:flush(true)

		max_x = pane.max_x
		local fileName = "Unknown"
		if resolvedFile.type == 'ok' and resolvedFile.value.class == 'file' then
			fileName = `{resolvedFile.value.name}.{resolvedFile.value.extension}`
		end

		local middle = max_x // 2
		local padding = string.rep(" ", middle - (#fileName))

		io:write(`{padding}{fileName}`, 'name')
		io:write(" ", "blank")
	end

	local function update()
		local currentPos = stream.value.player.TimePosition
		local percent = (currentPos / length)

		local maxSize = (max_x // 2)

		local i = ((maxSize * percent)) // 1
		local difference = maxSize - i

		local padding = string.rep(" ", ((max_x) // 4) - 4)

		local progress = `{string.rep("■", i)}{string.rep(" ", difference)}`
		local	currentStr = utility.toHHMMSS(currentPos)

		-- progress bar length
		local pSize = utf8.len(progress)

		io:write(`{padding}{currentStr}{string.rep(" ", pSize - #currentStr - #lengthStr + 4)}{lengthStr}`, "time")
		io:write(`{padding}-[{xterm256(progress, 2)}]-`, "progress")
	end

	setup()
	update()

	pane.janitor:Add(pane.signals.resized:Connect(setup), "Disconnect")

	while not interrupted do
		update()
		task.wait(0.125)
	end

	pane.AudioBus:remove(stream.value.index)

	return result.ok(nil)
end)