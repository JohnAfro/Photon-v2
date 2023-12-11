Photon2.Library = Photon2.Library or {
	Components = {},
	-- Stores copies of raw components 
	ComponentsGraph = {},
	Vehicles = {},
	---@type table<string, PhotonLibrarySiren>
	Sirens = {},
	InteractionSounds = {},
	Commands = {},

	InputConfigs = {},
	InputConfigsReady = false,

	Schemas = {},

	-- New Library system
	Types = {},
	Repository = {}
}

local library = Photon2.Library
local _g = _G
local Util = Photon2.Util

local componentsRoot = "photon-v2/library/components/"
local vehiclesRoot = "photon-v2/library/vehicles/"
local sirensRoot = "photon-v2/library/sirens/"
local interactionSoundsRoot = "photon-v2/library/interaction_sounds/"
local commandsRoot = "photon-v2/library/commands/"
local inputConfigurationsRoot = "photon-v2/library/input_configurations/"
local schemasRoot = "photon-v2/library/schemas/"

local printf = Photon2.Debug.PrintF
local print = Photon2.Debug.Print

-- local libraries = {
-- 	{ Name = "Input"}
-- }

---@type PhotonLibraryType
local inputConfigurations = {
	Name = "InputConfigurations",
	Folder = "input_configurations",
	Singular = "InputConfiguration",
	OnServer = false,
	ToJson = function( self, configProfile ) 
		return Photon2.ClientInput.ExportProfileToJson( configProfile )
	end,
	FromJson = function( self, json ) 
		return Photon2.ClientInput.ImportProfileFromJson( json )
	end,
	OnReload = function( self, profile )
		if ( Photon2.ClientInput.Active and ( Photon2.ClientInput.Active.Name == profile.Name ) ) then
			Photon2.Index.CompileInputConfigurationFromLibrary( profile.Name )
		else
			Photon2.Index.InputConfigurations[profile.Name] = nil
		end
	end
	-- LoadFile = function
}

local repository = Photon2.Library.Repository
local types = Photon2.Library.Types

---@param entry PhotonLibraryType
function Photon2.Library.AddType( entry )
	entry = PhotonLibraryType.New( entry )
end
Photon2.Library.AddType( inputConfigurations )

function Photon2.LoadComponentFile( filePath, isReload )
	Photon2.Debug.Print("Loading component file: " .. filePath)
	local nameStart = string.len(componentsRoot) + 1
	local nameEnd = string.len(componentsRoot) - nameStart - 4
	local name = string.sub(filePath, nameStart, nameEnd)
	Photon2.Debug.Print("Component name: " .. name)
	-- _COMPONENT = COMPONENT
	_UNSET = UNSET
	UNSET = PHOTON2_UNSET
	PHOTON_LIBRARY_COMPONENT = {}
	Photon2._acceptFileReload = false
	include( filePath )
	Photon2._acceptFileReload = true
	if (istable(library.Components[name])) then
		Photon2.Debug.Print("Component '" .. name .. "' already exists. Overwriting.")
	end
	PHOTON_LIBRARY_COMPONENT.Name = name
	library.Components[name] = PHOTON_LIBRARY_COMPONENT
	-- COMPONENT = _COMPONENT
	PHOTON_LIBRARY_COMPONENT = nil
	UNSET = _UNSET
	if (isReload) then
		Photon2.CompileComponent( name, library.Components[name] )
	end
end

function Photon2.LoadComponentLibrary( folderPath )
	folderPath = folderPath or ""
	local search = componentsRoot .. folderPath
	local files, folders = file.Find( search .. "*.lua", "LUA" )
	for _, fil in pairs( files ) do
		Photon2.LoadComponentFile( search .. fil )
	end
	hook.Call("Photon2.LoadComponentLibrary")
	Photon2.Index.ProcessComponentLibrary()
end

function Photon2.BuildParentLibraryComponent( childId, parentId )
	---@type PhotonLibraryComponent
	local parentLibraryComponent = Photon2.Library.Components[parentId]
	-- local libraryComponent = table.Copy(Photon2.Library.Components[parentId])
	if ( not parentLibraryComponent ) then
		error ("Component [" .. tostring(childId) .. "] attempted to inherit from parent component [" .. tostring( parentId ) .."], which could not be found." )
	end
	parentLibraryComponent = table.Copy( parentLibraryComponent )
	if ( parentLibraryComponent.Base ) then
		Util.Inherit( parentLibraryComponent, Photon2.BuildParentLibraryComponent( parentId, parentLibraryComponent.Base ))
	end
	return parentLibraryComponent
end

function Photon2.ReloadComponent( id )
	if (Photon2._acceptFileReload) then
		Photon2.Debug.Print( "Reloading component: " .. tostring(id) )
		Photon2.LoadComponentFile( componentsRoot .. id .. ".lua", true )
		return true
	end
	return false
end

---@param filePath string
---@param isReload? boolean
function Photon2.LoadVehicleFile( filePath, isReload )
	Photon2.Debug.Print("Loading vehicle file: " .. filePath)
	local nameStart = string.len(vehiclesRoot) + 1
	local nameEnd = string.len(vehiclesRoot) - nameStart - 4
	local name = filePath:sub(nameStart, nameEnd)
	Photon2.Debug.Print("Vehicle name: " .. name)
	---@type PhotonLibraryVehicle
	PHOTON2_LIBRARY_VEHICLE = {}
	Photon2._acceptFileReload = false
	include( filePath )
	Photon2._acceptFileReload = true
	if (istable(library.Vehicles[name])) then
		Photon2.Debug.Print("Vehicle '" .. name .. "' already exists. Overwriting.")
	end
	PHOTON2_LIBRARY_VEHICLE.ID = name
	library.Vehicles[name] = PHOTON2_LIBRARY_VEHICLE
	PHOTON2_LIBRARY_VEHICLE = nil
	printf("END of LoadVehicleFile() filepath: %s", filePath)
	printf("\tname: %s", name)
	Photon2.Index.CompileVehicle( name, library.Vehicles[name], isReload )
end

-- Returns the active library vehicle global when loading a vehicle file.
-- Workaround to ensure correct Lua annotation/suggestion behavior.
---@return PhotonLibraryVehicle
function Photon2.LibraryVehicle()
	return _g["PHOTON2_LIBRARY_VEHICLE"]
end

---@return PhotonLibraryComponent
function Photon2.LibraryComponent()
	return _g["PHOTON_LIBRARY_COMPONENT"]
end

function Photon2.LoadVehicleLibrary( folderPath )
	Photon2.Debug.Print("LoadVehicleLibrary() called")
	folderPath = folderPath or ""
	local search = vehiclesRoot .. folderPath
	local files, folders = file.Find( search .. "*.lua", "LUA" )
	for _, fil in pairs( files ) do
		Photon2.LoadVehicleFile( search .. fil )
	end
	Photon2.Debug.Print("LoadVehicleLibrary hook")
	
	hook.Call("Photon2.LoadVehicleLibrary")
	Photon2.Debug.Print("ProcessVehicleLibrary hook called()")
	Photon2.Index.ProcessVehicleLibrary()
end

function Photon2.ReloadComponentFile()
	if (Photon2._acceptFileReload) then
		local source = debug.getinfo(2, "S").source
		if source:sub(1, 1) == "@" then
			source = source:sub(2)
		else
			return false
		end
		
		local startPos, endPos = source:find(componentsRoot, 1, true)

		if (startPos) then
			local path = source:sub(startPos)
			Photon2.Debug.Print("Reloading component: " .. tostring(path))
			Photon2.LoadComponentFile( path, true )
		else
			Photon2.Debug.Print("Attempted to call ReloadComponentFile() from an invalid file location [" .. tostring(source) .."]")
			return false
		end

		return true
	end
	return false
end

function Photon2.ReloadVehicle( id )
	if (Photon2._acceptFileReload) then
		Photon2.Debug.Print("Reloading vehicle: " .. tostring(id))
		Photon2.LoadVehicleFile(vehiclesRoot .. id .. ".lua")
		return true
	end
	return false
end

function Photon2.ReloadVehicleFile()
	if (Photon2._acceptFileReload) then
		local source = debug.getinfo(2, "S").source
		if source:sub(1, 1) == "@" then
			source = source:sub(2)
		else
			return false
		end
		
		local startPos, endPos = source:find(vehiclesRoot, 1, true)

		if (startPos) then
			local path = source:sub(startPos)
			Photon2.Debug.Print("Reloading vehicle: " .. tostring(path))
			Photon2.LoadVehicleFile( path, true )
		else
			Photon2.Debug.Print("Attempted to call ReloadVehicleFile() from an invalid file location [" .. tostring(source) .."]")
			return false
		end

		return true
	end
	return false
end

function Photon2.LoadSirenFile( filePath, isReload )
	Photon2.Debug.Print( "Loading siren file: " .. filePath )
	Photon2._acceptFileReload = false
	include( filePath )
	Photon2._acceptFileReload = true
end

function Photon2.RegisterSiren( siren )
	Photon2.Library.Sirens[siren.Name] = siren
	Photon2.Index.CompileSiren( Photon2.Library.Sirens[siren.Name] )
end

function Photon2.LoadSirenLibrary()
	print( "LoadSirenLibrary() called." )
	folderPath = folderPath or ""
	local search = sirensRoot .. folderPath
	local files, folders = file.Find( search .. "*.lua", "LUA" )
	for _, fil in pairs( files ) do
		Photon2.LoadSirenFile( search .. fil )
	end
	hook.Call( "Photon2.LoadSirenLibrary" )
end

function Photon2.LoadInteractionSoundFile( filePath, isReload )
	Photon2.Debug.Print( "Loading interaction sound file: " .. filePath )
	Photon2._acceptFileReload = false
	include( filePath )
	Photon2._acceptFileReload = true
end

function Photon2.RegisterInteractionSound( profile )
	local library = Photon2.Library.InteractionSounds
	local class = profile.Class
	library[class] = library[class] or {}
	library[class][profile.Name] = profile
	return Photon2.Index.CompileInteractionSound( library[class][profile.Name] )
end

function Photon2.LoadInteractionSoundLibrary()
	print( "LoadInteractionSoundLibrary() called." )
	folderPath = folderPath or ""
	local search = interactionSoundsRoot .. folderPath
	local files, folders = file.Find( search .. "*.lua", "LUA" )
	for _, fil in pairs( files ) do
		Photon2.LoadInteractionSoundFile( search .. fil )
	end
	hook.Call( "Photon2.LoadInteractionSoundLibrary" )
end

function Photon2.Library.LoadCommandFile( filePath, isReload )
	Photon2.Debug.Print( "Loading command file: " .. filePath )
	Photon2._acceptFileReload = false
	include( filePath )
	Photon2._acceptFileReload = true
end

---@param command PhotonCommand
function Photon2.RegisterCommand( command )
	Photon2.Library.Commands[command.Name] = command
	return Photon2.Index.CompileInputCommand( command )
end

function Photon2.Library.LoadCommandLibrary()
	print( "Library.LoadCommandLibrary() called." )
	folderPath = folderPath or ""
	local search = commandsRoot .. folderPath
	local files, folders = file.Find( search .. "*.lua", "LUA" )
	for _, fil in pairs( files ) do
		Photon2.Library.LoadCommandFile( search .. fil )
	end
	hook.Call( "Photon2.LoadCommandLibrary" )
end

function Photon2.Library.LoadSchemaLibrary()
	print( "Library.LoadSchemaLibrary() called.")
	folderPath = folderPath or ""
	local search = schemasRoot .. folderPath
	local files, folders = file.Find( search .. "*.lua", "LUA" )
	for _, fil in pairs( files ) do
		include( search .. fil )
	end
	hook.Call( "Photon2.LoadSchemaLibrary" )
end

function Photon2.RegisterSchema( schema )
	Photon2.Library.Schemas[schema.Name] = schema
end

hook.Add("Initialize", "Photon2:InitializeLibrary", function()
	Photon2.LoadSirenLibrary()
	Photon2.LoadComponentLibrary()
	Photon2.Library.LoadSchemaLibrary()
	Photon2.LoadVehicleLibrary()
	Photon2.LoadInteractionSoundLibrary()
	Photon2.Library.LoadCommandLibrary()
	Photon2.LoadLibraries( { "InputConfigurations" } )

	if CLIENT then
		Photon2.ClientInput.SetActiveConfiguration( "default" )
	end
end)

---@param types string[]
function Photon2.LoadLibraries( types )
	for i=1, #types do
		---@type PhotonLibraryType
		local libraryType = Photon2.Library[types[i]]
		libraryType:LoadLibrary()
	end
end



if CLIENT then
	Photon2.Library.InputConfigurations:Export( "joystick_test", "joystick_test_json" )

end
-- Photon2.LoadLibraries( { "InputConfigurations" } )


-- if CLIENT then
	-- Photon2.Library.LoadInputConfigurationLibrary()
-- end