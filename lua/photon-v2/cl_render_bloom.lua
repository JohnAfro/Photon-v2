Photon2.RenderBloom = Photon2.RenderBloom or {
	RenderTime = 0,
	DrawTime = 0
}

local copyMaterial = Material( "pp/copy" )
local additiveMaterial = Material( "pp/add" )
local subtractiveMaterial = Material( "pp/sub" )

local textureFlags = 16 + 32768 + 32 + 4 + 8

local rtBloomOuter = GetRenderTargetEx( "Photon2_RT1", ScrW(), ScrH(), RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_SEPARATE, textureFlags, CREATERENDERTARGETFLAGS_HDR, IMAGE_FORMAT_BGRA8888 )
local rtMeshSource = GetRenderTargetEx( "Photon2_RT2", ScrW(), ScrH(), RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_NONE, textureFlags, CREATERENDERTARGETFLAGS_HDR, IMAGE_FORMAT_BGRA8888 )
local rtBloomInner = GetRenderTargetEx( "Photon2_RT3", ScrW(), ScrH(), RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_NONE, textureFlags, CREATERENDERTARGETFLAGS_HDR, IMAGE_FORMAT_BGRA8888 )
local storeRenderTarget = GetRenderTargetEx( "Photon2_RT4", ScrW(), ScrH(), RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_NONE, textureFlags, CREATERENDERTARGETFLAGS_HDR, IMAGE_FORMAT_BGRA8888 )

local additiveDrawMeshSourcePasses = GetConVar( "ph2_bloom_add_src_passes" )
local additiveDrawBloomOuterPasses = GetConVar( "ph2_bloom_add_outer_passes" )
local additiveDrawBloomInnerPasses = GetConVar( "ph2_bloom_add_inner_passes" )

local bloomOuterBlurPasses 	= GetConVar( "ph2_bloom_outer_blur_passes" )
local bloomOuterBlurX 		= GetConVar( "ph2_bloom_outer_blur_x" )
local bloomOuterBlurY 		= GetConVar( "ph2_bloom_outer_blur_y" )
      
local bloomInnerBlurPasses 	= GetConVar( "ph2_bloom_inner_blur_passes" )
local bloomInnerBlurX		= GetConVar( "ph2_bloom_inner_blur_x" )
local bloomInnerBlurY		= GetConVar( "ph2_bloom_inner_blur_y" )

---@param additive boolean Additive bloom pass.
function Photon2.RenderBloom.Render( additive )
	-- render.SuppressEngineLighting( true )
	-- render.TurnOnToneMapping()
	local scene = render.GetRenderTarget()
	render.CopyRenderTargetToTexture( storeRenderTarget )

	if ( additive ) then
		render.Clear( 0, 0, 0, 255, false, true )
	else
		render.Clear( 255, 255, 255, 255, false, true )
	end

	cam.Start3D()

		-- render.SuppressEngineLighting( true )

		render.SetStencilEnable( true )
		render.SetStencilWriteMask( 1 )
		render.SetStencilTestMask( 1 )
		render.SetStencilReferenceValue( 1 )

		render.SetStencilCompareFunction( STENCIL_ALWAYS )
		render.SetStencilPassOperation( STENCIL_REPLACE )
		render.SetStencilFailOperation( STENCIL_KEEP )
		render.SetStencilZFailOperation( STENCIL_KEEP )

		Photon2.RenderLightMesh.Render()
		render.CopyRenderTargetToTexture( rtMeshSource )

		-- RENDER MESHES
		Photon2.RenderLightMesh.DrawBloom()
		Photon2.RenderLight2D.DrawBloom()

		render.SetStencilCompareFunction( STENCIL_EQUAL )
		render.SetStencilPassOperation( STENCIL_KEEP )
		
		render.SetStencilEnable( false )
		-- render.SuppressEngineLighting( false )
	cam.End3D()
		
		
	render.CopyRenderTargetToTexture( rtBloomOuter )
	render.CopyRenderTargetToTexture( rtBloomInner )
	render.BlurRenderTarget( rtBloomOuter, bloomOuterBlurX:GetFloat(), bloomOuterBlurY:GetFloat(), bloomOuterBlurPasses:GetInt() )
	render.CopyRenderTargetToTexture( rtBloomOuter )
	
	render.BlurRenderTarget( rtBloomInner, bloomInnerBlurX:GetFloat(), bloomInnerBlurY:GetFloat(), bloomInnerBlurPasses:GetInt() )
	
	
	render.SetRenderTarget( scene )
	copyMaterial:SetTexture( "$basetexture", storeRenderTarget )
	copyMaterial:SetString( "$color", "1 1 1" )
	-- copyMaterial:SetString( "$alpha", "1" )
	render.SetMaterial( copyMaterial )
	render.DrawScreenQuad()
	-- render.SuppressEngineLighting( false )

	-- render.SetStencilEnable( true )
	-- render.SetStencilEnable( !additive )
		-- render.SetStencilCompareFunction( STENCIL_NOTEQUAL )

	-- -- 	if ( additive ) then
	-- 		-- additiveMaterial:SetTexture( "$basetexture", storeRT )
	-- 		additiveMaterial:SetTexture( "$basetexture", blurRenderTarget )
	-- 		render.SetMaterial( additiveMaterial )
	-- -- 	else
	-- -- 		subtractiveMaterial:SetTexture( "$basetexture", storeRT )
	-- -- 		-- subtractiveMaterial:SetTexture( "$basetexture", blurRenderTarget )
	-- -- 		render.SetMaterial( subtractiveMaterial )
	-- -- 	end

	-- -- 	-- for i=0, bloomPasses do
	-- -- 	-- 	render.DrawScreenQuad()
	-- -- 	-- end

	-- render.SetStencilEnable( false )

	-- render.SetStencilTestMask( 0 )
	-- render.SetStencilWriteMask( 0 )
	-- render.SetStencilReferenceValue( 0 )

end

function Photon2.RenderBloom.DrawAdditive()
	additiveMaterial:SetTexture( "$basetexture", rtBloomOuter )
	render.SetMaterial( additiveMaterial )
	for i=1, additiveDrawBloomOuterPasses:GetInt() do
		render.DrawScreenQuad()
	end
	
	additiveMaterial:SetTexture( "$basetexture", rtBloomInner )
	for i=1, additiveDrawBloomInnerPasses:GetInt() do
		render.DrawScreenQuad()
	end

	additiveMaterial:SetTexture( "$basetexture", rtMeshSource )
	for i=1, additiveDrawMeshSourcePasses:GetInt() do
		render.DrawScreenQuad()
	end
end

-- hook.Remove( "PreDrawViewModels", "Photon2.RenderBloom:Draw" )
-- hook.Remove( "PostDrawEffects", "Photon2.RenderBloom:Draw" )

hook.Add( "PostDrawEffects", "Photon2.RenderBloom:Draw", function( depth, sky )
	if ( ( #Photon2.RenderLightMesh.Active < 1 ) and ( #Photon2.RenderLight2D.Active < 1 ) ) then return end
	local start = SysTime()
	Photon2.RenderBloom.Render( true )
	Photon2.RenderBloom.DrawAdditive()
	Photon2.RenderBloom.DrawTime = SysTime() - start
end )