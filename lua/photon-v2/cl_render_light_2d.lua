Photon2.RenderLight2D = Photon2.RenderLight2D or {
	---@type PhotonElement2D[]
	Active = {},
}

local alternateActive = {}

local this = Photon2.RenderLight2D

local overlayConVar = GetConVar("ph2_debug_light_overlay")
local drawLights = GetConVar("ph2_draw_light2d")

local render = render

---@param color PhotonElementColor
local function invertColor( color )
	return color
	-- return { r = 0, g = 255, b = 512, a = 512 }
	-- return { r = (255 - color.TargetR) * color.Intensity, g = (255 - (color.TargetG * 2)) * color.Intensity, b = (255 - color.TargetB) * color.Intensity, a = 0 }
	-- return { r = 0, g = 0, b = 0, a = 0 }
	-- return { r = 255 - color.r, g = 255 - color.g, b = 255 - color.b, a = 255 }
end

function Photon2.RenderLight2D.OnPreRender()
	local activeLights = this.Active
	local nextTable = alternateActive
	local start = SysTime()
	for i=1, #activeLights do
		if (activeLights[i]) then
			nextTable[#nextTable+1] = activeLights[i]:DoPreRender()
		end
		activeLights[i] = nil
	end
	alternateActive = activeLights
	this.Active = nextTable
	this.PreRenderTime = SysTime() - start
end
hook.Add( "PreRender", "Photon2.Light2D:OnPreRender", this.OnPreRender )
-- hook.Remove( "PreRender", "Photon2.Light2D:OnPreRender")

local mat1 = Material("photon/sprites/sprite_generic")
-- local mat1_add = 
local mat_add = Material("sprites/emv/flare_secondary")
-- local mat1_add = Material("sprites/emv/flare_secondary")
local mat1_add = Material("photon/sprites/sprite_generic_add")

local spriteHint = Material("photon/debug/sprite_hint")

local light

function Photon2.RenderLight2D.DrawDebug()
	local activeLights = this.Active
	-- line/dev testing
	for i=1, #activeLights do
		light = activeLights[i] --[[@as PhotonElement2D]]
		if (light.ShouldDraw) then
		-- local angles = light.Matrix:GetAngles()
		-- local position = light.Matrix:GetTranslation()

		local angles = light.Angles
		local position = light.Position

		cam.Start3D2D( position, angles, 1 )
			render.SetMaterial(spriteHint)
			render.DrawQuad( light.Top, light.Right, light.Bottom, light.Left, Color(0, 255, 0) )
		cam.End3D2D()

		render.DrawLine(position, position + angles:Up() * 3, Color(0,0,255))
		render.DrawLine(position, position + angles:Right() * 3, Color(255,0,0))
		render.DrawLine(position, position + angles:Forward() * 3, Color(0,255,0))
		debugoverlay.Text( position, light.Id )

		if ( IsValid( light.Parent ) ) then
			render.DrawLine(position - light.Parent:GetAngles():Right() * 5, position + light.Parent:GetAngles():Right() * 5, Color(0,255,255))
			render.DrawLine(position - light.Parent:GetAngles():Forward() * 5, position + light.Parent:GetAngles():Forward() * 5, Color(255,255,0))
		end

		-- debugoverlay.Text(position, light.Id .. "(" .. tostring(  math.Round(light.ViewDot * 100) ) .. ") VIS: " .. tostring(math.Round(light.Visibility * 100)) .. "%", 0, false)
		end
	end
end



--[[
		RENDER OPTIONS		
--]]
local drawDetail 		= true
local drawShape 		= true
local drawGlow 			= true
local drawBloom 		= true
local drawSubtractive 	= GetConVar( "ph2_enable_subtractive_sprites" )
local drawAdditive 		= GetConVar("ph2_enable_additive_sprites")



function Photon2.RenderLight2D.DrawBloom()
	if not ( drawBloom ) then return end
	local activeLights = this.Active
	for i=1, #activeLights do
		light = activeLights[i] --[[@as PhotonElement2D]]
		if ( light.Shape and drawShape and ( not light.UIMode ) ) then
			render.SetMaterial( light.Shape --[[@as IMaterial]] )
			-- render.OverrideBlend( true, 1, 1, 2, 0, 0, 0 )
				-- render.DrawQuadEasy( light.Position, light.Angles:Forward(), light.Width * 1, light.Height * 1, invertColor( light.SourceFillColor ), light.Angles[3] - 180 )
				-- render.DrawQuadEasy( light.Position, light.Angles:Forward(), light.Width * 1, light.Height * 1, Color(255,255,255,0), light.Angles[3] - 180 )
			-- render.OverrideBlend( false )
			render.DrawQuadEasy( light.Position, light.Angles:Forward(), light.Width, light.Height, light.ShapeGlowColor, light.Angles[3] - 180 )
		end
	end
end

--[[
		SPRITE SCALE OPTIONS
--]]

local glowSize 	= 8
local subtractiveGlowMid = glowSize * 0.5
local subtractiveGlowOuter = glowSize * 2
local glow1 = subtractiveGlowOuter * 2
local glow2 = glowSize * 3

function Photon2.RenderLight2D.Render()
	local start = SysTime()
	-- if true then return end
	-- render.SetGoalToneMappingScale(090)
	-- render.SetAmbientLight(512,0,0)
	-- render.SetColorModulation(255,255,0)
	-- render.OverrideBlendFunc()

	render.OverrideColorWriteEnable( true, true )
	local activeLights = this.Active
	local shouldDrawAdditive = drawAdditive:GetBool()
	-- benchmark test

	-- local vectors = {}
	-- for i=1, 100 do
	-- 	local x = Vector( 10 + i, 20 + i, 30 + i ) * i
	-- 	vectors[#vectors+1] = x
	-- end

	--

	if ( drawLights:GetBool() ) then
		-- Draw glow effect sprites
		if (drawGlow ) then
			for i=1, #activeLights do
				light = activeLights[i] --[[@as PhotonElement2D]]
				if ( not light or not light.ShouldDraw or not light.DrawLightPoints or ( light.UIMode ) ) then continue end
				
				local subDot = math.pow( light.ViewDot, 1.2 ) * 0.9

				if (drawSubtractive:GetBool()) then
					render.OverrideBlend( true, 1, 1, 2, 0, 0, 0 )
					render.SetMaterial( mat1 )
					render.DrawSprite( light.EffectPosition, (subtractiveGlowOuter * light.Scale * light.Intensity) * subDot, (subtractiveGlowOuter * light.Scale * light.Intensity) * subDot, light.GlowColor )
					render.DrawSprite( light.EffectPosition, (subtractiveGlowMid * light.Scale * light.Intensity) * subDot, (subtractiveGlowMid * light.Scale * light.Intensity) * subDot, light.SubtractiveMid )
					if ( light.LightMatrixEnabled ) then
						for i=1, #light.WorldLightMatrix do
							render.DrawSprite( light.WorldLightMatrix[i], (subtractiveGlowOuter * light.Scale * light.LightMatrixScaleMultiplier * light.Intensity) * subDot, (subtractiveGlowOuter * light.Scale * light.LightMatrixScaleMultiplier * light.Intensity ) * light.ViewDot, light.GlowColor )
						end
					end
					render.OverrideBlend( false, 0, 0, 0 )
				end
				
				if ( shouldDrawAdditive ) then
					local newDot = math.pow( light.ViewDot, 1.5 ) * 1.3

					render.SetMaterial( mat1_add )
					render.DrawSprite( light.EffectPosition, (glow1 * light.Scale * light.Intensity) * newDot, (glow1 * light.Scale * light.Intensity) * newDot, ColorAlpha(light.InnerGlowColor, 64) )
					
					render.SetMaterial( mat_add )
					render.DrawSprite( light.EffectPosition, (glow2 * light.Scale * light.Intensity) * newDot, (glow2 * light.Scale * light.Intensity) * newDot, ColorAlpha(light.InnerGlowColor, 255) )
					
					if ( light.LightMatrixEnabled ) then
						for i=1, #light.WorldLightMatrix do
							render.DrawSprite( light.WorldLightMatrix[i], (glow2 * light.Scale * light.LightMatrixScaleMultiplier * light.Intensity) * newDot, (glow2 * light.Scale * light.LightMatrixScaleMultiplier * light.Intensity ) * newDot, light.InnerGlowColor )
						end
					end
				end
			end
		end

		for i=1, #activeLights do

			light = activeLights[i] --[[@as PhotonElement2D]]

			if ( not light or not light.ShouldDraw or light.CurrentStateId == "OFF" or light.UIMode ) then continue end

			if ( light.Detail and drawDetail ) then
				-- render.PushFilterMag( TEXFILTER.POINT )
				-- render.PushFilterMin( TEXFILTER.POINT )
				render.SetMaterial( light.Detail --[[@as IMaterial]] )
				-- render.DrawQuadEasy( light.Position, light.Angles:Forward(), light.Width * 1, light.Height * 1, light.SourceDetailColor, light.Angles[3] - 180 )
				
				render.OverrideBlend( true, 1, 1, 2, 0, 0, 0 )
					render.DrawQuadEasy( light.Position, light.Angles:Forward(), light.Width * 1, light.Height * 1, invertColor( light.SourceFillColor ), light.Angles[3] - 180 )
				render.OverrideBlend( false, 0, 0, 0 )
				
				render.DrawQuadEasy( light.Position, light.Angles:Forward(), light.Width * 1, light.Height * 1, light.SourceDetailColor, light.Angles[3] - 180 )
				-- render.PopFilterMag()
				-- render.PopFilterMin()
			end

			if ( light.Shape and drawShape ) then
				render.SetMaterial( light.Shape --[[@as IMaterial]] )
				-- render.DrawQuadEasy( light.Position, light.Angles:Forward(), light.Width * 1, light.Height * 1, light.SourceDetailColor, light.Angles[3] - 180 )
				
				-- render.OverrideBlend( true, 1, 1, 2, 0, 0, 0 )
					-- render.DrawQuadEasy( light.Position, light.Angles:Forward(), light.Width * 1, light.Height * 1, invertColor( light.SourceFillColor ), light.Angles[3] - 180 )
				-- render.OverrideBlend( false )
				
				render.DrawQuadEasy( light.Position, light.Angles:Forward(), light.Width * 1, light.Height * 1, light.ShapeGlowColor, light.Angles[3] - 180 )
			end
			
		end
			
	end
	-- cam.End3D()
	if (overlayConVar:GetBool()) then
		this.DrawDebug()
	end
	render.OverrideColorWriteEnable( false, false )
	this.RenderTime = SysTime() - start
end


-- hook.Add( "PreDrawEffects", "Photon2.Light2D:Render", this.Render )
-- hook.Remove( "PreDrawEffects", "Photon2.Light2D:Render" )
hook.Add( "PostDrawTranslucentRenderables", "Photon2.Light2D:Render", function( drawingDepth, drawingSkybox, draw3dSkybox)
	if (draw3dSkybox or drawingSkybox or draw3dSkybox) then return end
	this.Render()
end)

function Photon2.RenderLight2D.DrawUI()
	render.OverrideColorWriteEnable( true, true )
	local activeLights = this.Active
	for i=1, #activeLights do

		light = activeLights[i] --[[@as PhotonElement2D]]

		if ( not light or not light.ShouldDraw or light.CurrentStateId == "OFF" or ( not light.UIMode ) ) then continue end

		if ( light.Detail and drawDetail ) then
			-- render.PushFilterMag( TEXFILTER.POINT )
			-- render.PushFilterMin( TEXFILTER.POINT )
			render.SetMaterial( light.Detail --[[@as IMaterial]] )
			-- render.DrawQuadEasy( light.Position, light.Angles:Forward(), light.Width * 1, light.Height * 1, light.SourceDetailColor, light.Angles[3] - 180 )
			
			render.OverrideBlend( true, 1, 1, 2, 0, 0, 0 )
				render.DrawQuadEasy( light.Position, light.Angles:Forward(), light.Width * 1, light.Height * 1, invertColor( light.SourceFillColor ), light.Angles[3] - 180 )
			render.OverrideBlend( false, 0, 0, 0 )
			
			render.DrawQuadEasy( light.Position, light.Angles:Forward(), light.Width * 1, light.Height * 1, light.SourceDetailColor, light.Angles[3] - 180 )
			-- render.PopFilterMag()
			-- render.PopFilterMin()
		end

		if ( light.Shape and drawShape ) then
			render.SetMaterial( light.Shape --[[@as IMaterial]] )
			-- render.DrawQuadEasy( light.Position, light.Angles:Forward(), light.Width * 1, light.Height * 1, light.SourceDetailColor, light.Angles[3] - 180 )
			
			-- render.OverrideBlend( true, 1, 1, 2, 0, 0, 0 )
				-- render.DrawQuadEasy( light.Position, light.Angles:Forward(), light.Width * 1, light.Height * 1, invertColor( light.SourceFillColor ), light.Angles[3] - 180 )
			-- render.OverrideBlend( false )
			
			render.DrawQuadEasy( light.Position, light.Angles:Forward(), light.Width * 1, light.Height * 1, light.ShapeGlowColor, light.Angles[3] - 180 )
		end
		light.ScreenPosition = light.Position:ToScreen()

	end
	render.OverrideColorWriteEnable( false, false )
end

