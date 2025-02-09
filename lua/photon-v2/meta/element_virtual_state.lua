if (exmeta.ReloadFile()) then return end

NAME = "PhotonElementVirtualState"
BASE = "PhotonElementState"

---@class PhotonElementVirtualState : PhotonElementVirtualProperties, PhotonElementState
local State = exmeta.New()

function State.New( self, name, data, collection )
	return PhotonElementState.New( PhotonElementState, name, data, collection )
end