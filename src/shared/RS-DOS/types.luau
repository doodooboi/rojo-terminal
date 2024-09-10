--[[
Name: types.luau
Description: All types used

Creator: SquelchMaster
Date: 08/03/2024 
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Shared.Signal)
local Janitor = require(ReplicatedStorage.Shared.Janitor)

export type Ok<T> = {type: 'ok', value: T}
export type Err<E> = {type: 'err', err: E}

export type Result<T, E> = Ok<T> | Err<E>
export type Map<K, V> = {[K]: V}

export type ObjectMetadata<class> = {
	name: string,

	metadata: {
		created: number,
		path: string,

		size: number
	},

	security: {
		owner: boolean,

		permissions: Map<string, string>?
	},

	class: class
}

export type File = ObjectMetadata<"file"> & {
	extension: string,
	contents: string,
}

export type Directory = ObjectMetadata<"directory"> & {
	contents: Map<string, File | Directory>,
	
	back: string,

	root: boolean?,
	home: boolean?,
}

export type Argument = {
	name: string,
	description: string,
	
	optional: boolean?
}

export type Command = {
	name: string,
	aliases: {string},
	description: string,
	
	arguments: {Argument},
	callback: CommandCallback
}

export type CommandCallback = (
	elevated: boolean, 
	arguments: {string}, 
	io: IOManager,
	pane: pane
) -> Result<any, string>

export type impl_AudioBus = {
	__index: impl_AudioBus,

	new: () -> AudioBus,
	setGlobalVolume: (self: AudioBus, volume: number) -> (),

	stream: (self: AudioBus, assetID: string) -> Result<{
		index: number,
		player: AudioPlayer
	}, string>,

	analyze: (self: AudioBus, stream: AudioPlayer) -> AudioAnalyzer,
	remove: (self: AudioBus, stream: number) -> (),

	togglePlayback: (self: AudioBus, stream: number) -> (),
	
	flush: (self: AudioBus) -> (),
	destroy: (self: AudioBus) -> (),
}

export type AudioBus = typeof(setmetatable({} :: {
	_streams: {AudioPlayer},
	_output: AudioDeviceOutput,

	volume: number,
}, {} :: impl_AudioBus))

export type impl_IOManager = {
	__index: impl_IOManager,

	new: () -> IOManager,	
	write: (self: IOManager, text: string, label: string?) -> number,
	render: (self: IOManager) -> string,
	deferUpdates: (self: IOManager, deferred: boolean, update: boolean?) -> (),

	-- allocates empty space 
	reserve: (self: IOManager, count: number) -> (number, number),
	push: (self: IOManager, label: string) -> number,
	
	swap: (self: IOManager) -> (),
	read: (self: IOManager, text: string?, pattern: string?) -> string,

	flush: (self: IOManager, stdout: boolean?) -> (),
	size: (self: IOManager) -> number,
}

export type IOManager = typeof(setmetatable({} :: {
	buffer: {string},
	
	memory: Map<string, number>,
	
	stdin: {
		prefix: string,
		pattern: string?,
		waiting: boolean,

		request: Signal.Signal<>,
		recieve: Signal.Signal<string>,
	},

	updated: Signal.Signal<>,
	buffering: boolean,
	
	-- are buffers swapped? (primary false)
	_swapBuffer: {string},
	_swapMemory: Map<string, number>,

	_swapped: boolean,
	_reserved: boolean,
}, {} :: impl_IOManager))

type direction = 'left' | 'right' | 'down' | 'up'

export type impl_paneManager = {
	__index: impl_paneManager,

	paneFocused: Signal.Signal<pane, 'focused' | 'unfocused'>,
	paneCreated: Signal.Signal<pane>,
	
	getPaneByFrame: (self: paneManager, frame: GuiObject) -> pane,
	attach: (container: Frame, template: GuiObject) -> paneManager,
	start: (self: paneManager) -> (),

	-- returns the newly focused pane
	split: (self: paneManager, direction: direction) -> pane,
	close: (self: paneManager, all: boolean?) -> (),

	getFocused: (self: paneManager) -> pane,
	setFocused: (self: paneManager, newPane: pane) -> (),
}

export type paneManager = typeof(setmetatable({} :: {
	container: Frame,
	template: GuiObject,
	focused: pane,

	_panes: {pane},
	_lookup: Map<GuiObject, pane>
}, {} :: impl_paneManager))

export type impl_pane = {
	__index: impl_pane,

	paneFocusEvent: Signal.Signal<pane, 'focused' | 'unfocused'>,
	paneCreated: Signal.Signal<pane>,

	new: (parent: Frame, UI: GuiObject) -> pane,
	close: (self: pane) -> (),

	focus: (self: pane) -> (),
	unfocus: (self: pane) -> (),
	reparent: (self: pane, new: Frame) -> (),

	-- History
	remember: (self: pane, command: string) -> (),
	getSaved: (self: pane, direction: 'down' | 'up') -> string?,

	-- Track any events
	track: (self: pane, connection: RBXScriptConnection, tillPaneClosed: boolean?) -> (),
	getUI: (self: pane) -> GuiObject,

	_recalculateMaxCharacters: (self: pane, char: string?) -> (),
}

export type pane = typeof(setmetatable({} :: {
	IOManager: IOManager,
	AudioBus: AudioBus,
	
	at: {
		directory: Directory,
		path: string,
		pwd: string,
	},

	history: {string},
	
	ui: GuiObject,
	parent: Frame,

	janitor: Janitor.Janitor,

	connections: { 
		focused: {RBXScriptConnection}, 
		pane: {RBXScriptConnection},

		-- For commands so they may clean properly
		running: {RBXScriptConnection}
	},

	-- Max characters on one line
	max_x: number,
	-- Max 
	max_y: number,

	signals: {
		SIGINT: Signal.Signal<>,
		SIGKILL: Signal.Signal<>,

		resized: Signal.Signal<>,
		processed: Signal.Signal<Result<Result<any, string>, string>>
	},

	-- The current binary being ran
	-- We store it so we can cancel it in case of SIGKILL
	running: thread?,

	focused: boolean,
	yielded: boolean,

	_rememberIndex: number,
}, {} :: impl_pane))

return {}