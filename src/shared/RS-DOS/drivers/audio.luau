--!strict
--[[
Name: audio.luau
Description: Manages all audio related buses

Creator: SquelchMaster
Date: 08/11/2024 
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RSDOS = ReplicatedStorage["RS-DOS"]
local types = require(RSDOS.types)
local result = require(RSDOS.result)

local AudioBus: types.impl_AudioBus = {} :: types.impl_AudioBus
AudioBus.__index = AudioBus

function AudioBus.new()
	local DeviceOutput = Instance.new("AudioDeviceOutput")
	DeviceOutput.Player = Players.LocalPlayer
	DeviceOutput.Parent = workspace

	local self = setmetatable({
		_streams = {},
		_output = DeviceOutput,

		volume = 1,
	}, AudioBus)

	return self
end

function AudioBus:stream(assetID)
	local player = Instance.new("AudioPlayer")
	player.AssetId = assetID
	player.Parent = workspace

	local wire = Instance.new("Wire")
	wire.SourceInstance = player
	wire.TargetInstance = self._output
	wire.Parent = player

	local timeout = 5
	local elapsed = 0

	repeat 
		elapsed += task.wait()
	until elapsed > timeout or player.IsReady

	if elapsed > timeout then
		wire:Destroy()
		player:Destroy()

		return result.err(`Timed out loading '{assetID}'`)
	end

	local ind = #self._streams + 1
	self._streams[ind] = player

	player.Volume = self.volume
	player:Play()

	return result.ok({
		index = ind,
		player = player
	})
end

function AudioBus:analyze(stream)
	local Analyzer = Instance.new("AudioAnalyzer")
	Analyzer.Parent = stream
	
	local Wire = Instance.new("Wire")
	Wire.Name = "AnalyzerBus"
	
	Wire.SourceInstance = stream
	Wire.TargetInstance = Analyzer
	Wire.Parent = stream

	return Analyzer
end

function AudioBus:togglePlayback(stream)
	
end

function AudioBus:remove(stream: number)
	local player = self._streams[stream]
	if not player then return end

	player:Destroy()

	self._streams[stream] = nil
end

function AudioBus:flush()
	for i in ipairs(self._streams) do
		self:remove(i)
	end
end

function AudioBus:setGlobalVolume(new)
	for _, player in ipairs(self._streams) do
		player.Volume = new
	end
end

function AudioBus:destroy()
	self:flush()
end

return AudioBus