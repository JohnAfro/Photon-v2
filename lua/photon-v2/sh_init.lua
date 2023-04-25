include("sh_functions.lua")
include("sh_component_builder.lua")
include("sh_sequence_builder.lua")
include("sh_schema.lua")

function LoadPhoton2MetaFiles()
	exmeta.LoadFile("photon-v2/meta/light_color.lua")
	exmeta.LoadFile("photon-v2/meta/light_state.lua")
	exmeta.LoadFile("photon-v2/meta/light_2d_state.lua")

	exmeta.LoadFile("photon-v2/meta/light.lua")
	exmeta.LoadFile("photon-v2/meta/light_2d.lua")

	exmeta.LoadFile("photon-v2/meta/base_entity.lua")

	exmeta.LoadFile("photon-v2/meta/lighting_component.lua")
	exmeta.LoadFile("photon-v2/meta/lighting_segment.lua")
	exmeta.LoadFile("photon-v2/meta/sequence.lua")
	exmeta.LoadFile("photon-v2/meta/sequence_collection.lua")

	exmeta.LoadFile("photon-v2/meta/vehicle_equipment.lua")
	exmeta.LoadFile("photon-v2/meta/vehicle.lua")
end

LoadPhoton2MetaFiles()

if CLIENT then
	hook.Add("Initialize", "Photon2:Initialize", LoadPhoton2MetaFiles)
end
