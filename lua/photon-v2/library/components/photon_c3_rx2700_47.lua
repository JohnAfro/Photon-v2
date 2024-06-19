if (Photon2.ReloadComponentFile()) then return end
local COMPONENT = Photon2.LibraryComponent()
local sequence = Photon2.SequenceBuilder.New

COMPONENT.Author = "Photon"

COMPONENT.Credits = {
	Model = "Cj24, Schmal",
	Code = "Schmal"
}

COMPONENT.Title = [[Code 3 RX2700 (47")]]
COMPONENT.Category = "Lightbar"
COMPONENT.Model = "models/schmal/code3_rx2700_47.mdl"

COMPONENT.Preview = {
	Position = Vector( 0, 0, -0.5 ),
	Angles = Angle( 0, 180, 0 ),
	Zoom = 1.2
}

local w = 7.1
local h = w/2

COMPONENT.Templates = {
	["2D"] = {
		["Linear"] = {
			Shape = PhotonMaterial.GenerateLightQuad("photon/lights/rx2700_linear_shape.png").MaterialName,
			Detail = PhotonMaterial.GenerateLightQuad("photon/lights/rx2700_linear_detail.png").MaterialName,
			-- Detail = PhotonMaterial.GenerateLightQuad("photon/lights/whe_lib_detail.png").MaterialName,
			Width = w,
			Height = h,
			Scale = 1.8,
			Ratio = 1.5
		},
		["Takedown"] = {
			Shape = PhotonMaterial.GenerateLightQuad("photon/lights/rx2700_takedown_shape.png").MaterialName,
			Detail = PhotonMaterial.GenerateLightQuad("photon/lights/rx2700_takedown_shape.png").MaterialName,
			-- Detail = PhotonMaterial.GenerateLightQuad("photon/lights/whe_lib_detail.png").MaterialName,
			Width = 2,
			Height = 2,
			Scale = 1.8,
		}
	},
	["Projected"] = {
		TakedownIllumination = {
			Material = "photon/flashlight/led_linear.png",
			Brightness = 2
		},
		AlleyIllumination = {
			Material = "photon/flashlight/led_linear.png",
			Brightness = 4
		},
	}
}

local domeColors = {
	["black"] = "schmal/photon/code3_rx2700/dome_color_black",
	["red"] = "schmal/photon/code3_rx2700/dome_color_red",
	["blue"] = "schmal/photon/code3_rx2700/dome_color_blue",
	["clear"] = "schmal/photon/code3_rx2700/dome_color_clear",
	["amber"] = "schmal/photon/code3_rx2700/dome_color_amber",
}

COMPONENT.DefineOptions = {
	["Feet"] = {
		Arguments = { { "width", "number" } },
		Description = "Sets the width of the feet placement.",
		Action = function( self, width )
			-- TODO: verify this if this is necessary and/or works
			-- local scale = self.Scale or 1
			-- width = width * scale
			self.Bones = self.Bones or {}
			self.Bones["right_foot"] = { Vector( width, 0, 0 ), Angle( 0, 0, 0 ), scale }
			self.Bones["left_foot"] = { Vector( -width, 0, 0 ), Angle( 0, 0, 0 ), scale }
			self.Bones["left_original_foot"] = { Vector( width, 0, 0 ), Angle( 0, 0, 0 ), scale }
			self.Bones["right_original_foot"] = { Vector( -width, 0, 0 ), Angle( 0, 0, 0 ), scale }
		end
	},
	["Mount"] = {
		Arguments = { { "mount", "string" } },
		Description = "Sets mounting feet type. (normal, no-hook, classic, none)",
		Action = function( self, mount )
			self.BodyGroups = self.BodyGroups or {}
			if ( mount == "no-hook" ) then
				self.BodyGroups["Feet"] = 1
			elseif ( mount == "classic" ) then
				self.BodyGroups["Feet"] = 2
			elseif ( mount == "none" ) then
				self.BodyGroups["Feet"] = 3
			else
				self.BodyGroups["Feet"] = 0
			end
		end
	},
	["Domes"] = {
		Arguments = { 
			{ "left", "string" },
			{ "center", "string" },
			{ "right", "string" },
		},
		Description = "Changes the dome material. (black, red, blue, clear, amber)",
		Action = function( self, left, center, right )
			self.SubMaterials = self.SubMaterials or {}
			self.SubMaterials[7] = domeColors[left]
			self.SubMaterials[8] = domeColors[center or left]
			self.SubMaterials[9] = domeColors[right or left]
		end
	
	}
}

COMPONENT.StateMap = "[R] 1 3 5 7 9 11 13 14 [B] 2 4 6 8 10 12 [W] 15 16 17 18 19 20 21"

COMPONENT.Elements = {
	[1] = { "Linear", Vector( 6.62, 0, -1.36 ), Angle( 0, -90, 0 ) },
	
	[2] = { "Linear", Vector( 6.62, -10, -1.36 ), Angle( 0, -90, 0 ) },
	[3] = { "Linear", Vector( 6.62, 10, -1.36 ), Angle( 0, -90, 0 ) },
	
	[4] = { "Linear", Vector( 6.62, -16.85, -1.36 ), Angle( 0, -90, 0 ) },
	[5] = { "Linear", Vector( 6.62, 16.85, -1.36 ), Angle( 0, -90, 0 ) },
	
	[6] = { "Linear", Vector( 4.25, -23.6, -1.36 ), Angle( 0, -90 - 45, 0 ) },
	[7] = { "Linear", Vector( 4.25, 23.6, -1.36 ), Angle( 0, -90 + 45, 0 ) },
	
	[8] = { "Linear", Vector( -4.25, -23.6, -1.36 ), Angle( 0, 90 + 45, 0 ) },
	[9] = { "Linear", Vector( -4.25, 23.6, -1.36 ), Angle( 0, 90 - 45, 0 ) },
	
	[10] = { "Linear", Vector( -6.62, -16.85, -1.36 ), Angle( 0, 90, 0 ) },
	[11] = { "Linear", Vector( -6.62, 16.85, -1.36 ), Angle( 0, 90, 0 ) },
	
	[12] = { "Linear", Vector( -6.62, -10, -1.36 ), Angle( 0, 90, 0 ) },
	[13] = { "Linear", Vector( -6.62, 10, -1.36 ), Angle( 0, 90, 0 ) },

	[14] = { "Linear", Vector( -6.62, 0, -1.36 ), Angle( 0, 90, 0 ) },

	[15] = { "Takedown", Vector( 5.9, 4.5, -1.35 ), Angle( 0, -90, 0 ) },
	[16] = { "Takedown", Vector( 5.9, -4.5, -1.35 ), Angle( 0, -90, 0 ) },
	
	[17] = { "Takedown", Vector( 0, 25, -1.35 ), Angle( 0, 0, 0 ) },
	[18] = { "Takedown", Vector( 0, -25, -1.35 ), Angle( 0, 180, 0 ) },

	[19] = { "AlleyIllumination", Vector( 0, 25, -1.35 ), Angle( 0, 0, 0 ) },
	[20] = { "AlleyIllumination", Vector( 0, -25, -1.35 ), Angle( 0, 180, 0 ) },
	
	[21] = { "TakedownIllumination", Vector( 7, 0, -1.35 ), Angle( 0, -90, 0 ) },
}

COMPONENT.Segments = {
	All = {
		Frames = {
			[1] = "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18",
		},
		Sequences = {
			["ON"] = { 1 },
		}
	},
	Marker = {
		Frames = {
			[1] = "6 8 7 9",
		},
		Sequences = {
			["ON"] = { 1 },
		}
	},
	AlleyLeft = {
		Frames = {
			[1] = "",
			[2] = "17 19",
		},
		Sequences = {
			["ON"] = { 1 },
			["ILLUM"] = { 2 },
		}
	},
	AlleyRight = {
		Frames = {
			[1] = "",
			[2] = "18 20",
		},
		Sequences = {
			["ON"] = { 1 },
			["ILLUM"] = { 2 },
		}
	},
	Takedown = {
		Frames = {
			[1] = "15 16 21",
		},
		Sequences = {
			["ON"] = { 1 },
		}
	},
}

COMPONENT.Inputs = {
	["Emergency.Warning"] = {
		["MODE1"] = { All = "ON" },
		["MODE2"] = { All = "ON" },
		["MODE3"] = { All = "ON" },
	},
	["Emergency.SceneLeft"] = {
		["ON"] = { AlleyLeft = "ILLUM" }
	},
	["Emergency.SceneRight"] = {
		["ON"] = { AlleyRight = "ILLUM" }
	},
	["Emergency.SceneForward"] = {
		["ON"] = { Takedown = "ON" },
		["FLOOD"] = { Takedown = "ON" },
	},
	["Emergency.Marker"] = {
		["ON"] = { Marker = "ON" }
	}
}