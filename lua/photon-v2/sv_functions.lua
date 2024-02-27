local saveSteeringOnExit = true

local CurTime = CurTime

-- local ENT = FindMetaTable( "Entity" )

-- if not ENT._oldSetKeyValue then
-- 	ENT._oldSetKeyValue = ENT.SetKeyValue
-- 	ENT.SetKeyValue = function( self, key, value )
-- 		print("SETTING KEY VALUE " .. tostring(key) .. ": " .. tostring(value))
-- 		if (key == "vehiclename") then
-- 			self["@vehiclename"] = value
-- 			return
-- 		end
-- 		self:_oldSetKeyValue( key, value )
-- 	end
-- end

-- Workaround function. Modifies vehicle list KeyValues to store vehicle ID in "puntsound" property.
function Photon2.RunVehicleListModification()
	-- For addons that spawn vehicles without explicitly setting the .VehicleName property,
	-- the vehicle index will be stored as internal value "puntsound" if the spawning code iterates 
	-- over KeyValues to set each of them (which it likely does). Photon 2 will then detect this
	-- automatically and set the .VehicleName on its own, before then resetting the internal value.
	--
	-- The "puntsound" variable is used because it stores as a string and is generally unused.
	--
	local vehicles = list.Get( "Vehicles" ) --[[@as table]]
	for key, vehicle in pairs( vehicles ) do
		list.GetForEdit( "Vehicles" )[key]["KeyValues"]["vehiclename"] = key
	end
end
-- hook.Add( "Initialize", "Photon2:RunVehicleListModification", Photon2.RunVehicleListModification )
-- hook.Add( "InitPostEntity", "Photon2:RunVehicleListModification", Photon2.RunVehicleListModification )

-- Photon2.RunVehicleListModification()

local holdDuration = 0.2

local vehicleEntryPause = {}
local activeUseHeld = {}

hook.Add( "StartCommand", "Photon2:StartCommand", function( ply, ucmd ) 
	if ( IsValid( ply ) and IsValid( ply:GetVehicle() ) and ( ply:GetVehicle().PhotonEngineIdleEnabled ) ) then
		if ( ucmd:KeyDown( IN_USE ) ) then
			if ( not vehicleEntryPause[ply] ) then
				activeUseHeld[ply] = activeUseHeld[ply] or CurTime()
				if ( activeUseHeld[ply] + holdDuration > CurTime() ) then
					ucmd:RemoveKey( IN_USE )
				else
					ply:GetVehicle().PhotonEngineIdleOff = true
					ply.PhotonEngineIdleExit = activeUseHeld[ply]
					activeUseHeld[ply] = nil
				end
			end
		else
			if ( vehicleEntryPause[ply] ) then
				vehicleEntryPause[ply] = nil
			elseif ( activeUseHeld[ply] ) then
				ucmd:AddKey( IN_USE )
				ply.PhotonEngineIdleExit = activeUseHeld[ply]
				activeUseHeld[ply] = nil
			end
		end
	end
end)


---@param ply Entity
---@param vehicle Vehicle
---@param role any
function Photon2.OnPlayerEnteredVehicle( ply, vehicle, role )

	if ( vehicle.PhotonEngineIdleEnabled ) then
		vehicleEntryPause[ply] = true
		vehicle.PhotonEngineIdleOff = nil
	end

	local controller = vehicle:GetPhotonControllerFromAncestor() --[[@as sv_PhotonController]]
	if ( not IsValid( controller ) ) then return end
	
	if ( controller.IsLinkedToStandardVehicle and ( vehicle:GetPhotonController() == controller ) and ( vehicle:GetDriver() == ply ) ) then
		controller:PlayerEnteredLinkedVehicle( ply, vehicle, role )
	elseif ( not controller.IsLinkedToStandardVehicle ) then
		controller:PlayerEnteredLinkedVehicle( ply, vehicle, role )
	end

end
hook.Add( "PlayerEnteredVehicle", "Photon2:OnPlayerEnteredVehicle", Photon2.OnPlayerEnteredVehicle )

function Photon2.OnPlayerLeaveVehicle( ply, vehicle )

	local controller = vehicle:GetPhotonControllerFromAncestor()
	if ( IsValid( controller ) ) then
		if ( controller.IsLinkedToStandardVehicle ) then
			if ( vehicle:GetPhotonController() == controller ) then
				vehicle:GetPhotonControllerFromAncestor():PlayerExitedLinkedVehicle( ply, vehicle )
			end
		else
			vehicle:GetPhotonControllerFromAncestor():PlayerExitedLinkedVehicle( ply, vehicle )
		end
	end

	Photon2.sv_Network.NotifyPlayerInputController( ply, nil )

	-- TODO: needs to account for custom vehicle bases
	if ( saveSteeringOnExit ) then
		local steering = vehicle:GetSteeringDegrees() * vehicle:GetSteering()
		local increment = 1
		if ( steering < 0 ) then increment = increment * -1; steering = steering * -1 end
		for i=1,math.Round(steering) do
			vehicle:Fire( "steer", increment )
		end
	end

end
hook.Add( "PlayerLeaveVehicle", "Photon2:OnPlayerLeaveVehicle", Photon2.OnPlayerLeaveVehicle )

function Photon2.OnVehicleMove( ply, vehicle, moveData )
	if ( IsValid( vehicle:GetPhotonController() ) ) then
		vehicle:GetPhotonController():UpdateVehicleParameters( ply, vehicle, moveData )
	end
	-- print(vehicle:GetSteering())
end
hook.Add( "VehicleMove", "Photon2:OnVehicleMove", Photon2.OnVehicleMove )

local lastModelAttachScanTime = 0
local modelAttachScanRate = 1

-- for compatability with SGM's model attachment framework
function Photon2.ModelAttachBridgeScan()
	if ( not ( SGM and SGM.AttachedModels ) ) then return end
	if ( CurTime() < ( lastModelAttachScanTime + modelAttachScanRate) ) then return end
	for k, ent in pairs( SGM.AttachedModels ) do
		if ( not ( ent.SyncSubMaterials or ent.Sync ) ) then continue end
		if ( ent:GetNW2Bool( "Photon2.SyncSubMaterials" ) ) then continue end
		if not ( IsValid( ent:GetParent() ) and IsValid( ent:GetParent():GetPhotonController() ) ) then return end
		ent:SetNW2Bool( "Photon2.SyncSubMaterials", true )
	end
	lastModelAttachScanTime = CurTime()
end
hook.Add( "Think", "Photon2:ModelAttachBridgeScan", Photon2.ModelAttachBridgeScan )