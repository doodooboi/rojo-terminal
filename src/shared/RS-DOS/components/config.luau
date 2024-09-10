local Player = game:GetService("Players").LocalPlayer

return {
	ReservedNames = {
		".", "..",
	},
	ProtectedDirectories = {
		'boot',
		'dev',
		'bin',
		'etc'
	},
	HomeDirectory = Player.Name:lower()
}